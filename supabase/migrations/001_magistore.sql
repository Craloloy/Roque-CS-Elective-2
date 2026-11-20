-- Run once in Supabase SQL Editor. One transaction; existing schemas are never replaced.
begin;
create schema magistore;
revoke all on schema magistore from public, anon, authenticated;
grant usage on schema magistore to authenticated;
set local search_path = magistore, pg_catalog;

create table roles (
  id bigint generated always as identity primary key,
  role varchar(16) not null unique check (role in ('customer','admin')),
  created_at timestamptz not null default now(),
  encoded_by uuid references auth.users(id) on delete set null
);
insert into roles(role) values ('customer'),('admin');
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  email text, firstname text, lastname text,
  role_id bigint not null references roles(id)
);
create table categories (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  name text not null check (length(btrim(name)) between 1 and 80)
);
create unique index categories_name_key on categories(lower(btrim(name)));
create table products (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  name text not null check (length(btrim(name)) between 1 and 160),
  description text not null default '',
  stock integer not null check (stock >= 0),
  image_url text not null check (btrim(image_url) <> ''),
  category_id bigint not null references categories(id) on delete restrict,
  price numeric(12,2) not null check (price >= 0 and price <> 'NaN'::numeric)
);
create index products_category_price on products(category_id,price,id);
create table orders (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  user_id uuid not null references auth.users(id),
  status text not null default 'done' check (status in ('done','ready','collected')),
  total numeric(18,2) not null default 0 check (total >= 0),
  request_id uuid not null,
  unique (user_id,request_id)
);
create index orders_by_customer on orders(user_id,created_at desc,id desc);
create table order_items (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  order_id bigint not null references orders(id) on delete cascade,
  product_id bigint references products(id) on delete set null,
  product_name text not null,
  unit_price numeric(12,2) not null check (unit_price >= 0),
  quantity bigint not null check (quantity > 0)
);
create index order_items_by_order on order_items(order_id);
create index order_items_by_product on order_items(product_id);

create function magistore.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into magistore.profiles(id,email,firstname,lastname,role_id)
  select new.id,new.email,coalesce(new.raw_user_meta_data->>'firstname',new.raw_user_meta_data->>'given_name'),
         coalesce(new.raw_user_meta_data->>'lastname',new.raw_user_meta_data->>'family_name'),r.id
  from magistore.roles r where r.role='customer';
  return new;
end $$;
create trigger magistore_on_auth_user_created after insert on auth.users
for each row execute function magistore.handle_new_user();
insert into profiles(id,email,firstname,lastname,role_id)
select u.id,u.email,coalesce(u.raw_user_meta_data->>'firstname',u.raw_user_meta_data->>'given_name'),
       coalesce(u.raw_user_meta_data->>'lastname',u.raw_user_meta_data->>'family_name'),r.id
from auth.users u cross join roles r where r.role='customer' on conflict (id) do nothing;

create function magistore.is_admin() returns boolean language sql stable
security definer set search_path = '' as $$
  select exists(select 1 from magistore.profiles p join magistore.roles r on r.id=p.role_id
                where p.id=auth.uid() and r.role='admin');
$$;

alter table profiles enable row level security;
alter table roles enable row level security;
alter table categories enable row level security;
alter table products enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;
revoke all on all tables in schema magistore from anon, authenticated, public;
revoke all on all sequences in schema magistore from anon, authenticated, public;
grant select on roles,profiles,categories,products,orders,order_items to authenticated;
grant update(firstname,lastname) on profiles to authenticated;
grant insert(name),update(name),delete on categories to authenticated;
grant insert(name,description,stock,image_url,category_id,price),
  update(name,description,stock,image_url,category_id,price),delete on products to authenticated;
grant update(status) on orders to authenticated;
grant usage on sequence categories_id_seq,products_id_seq to authenticated;

create policy roles_read on roles for select to authenticated using (true);
create policy profiles_read on profiles for select to authenticated
  using (id=(select auth.uid()) or (select magistore.is_admin()));
create policy profile_edit_own on profiles for update to authenticated
  using (id=(select auth.uid()) and not (select magistore.is_admin()))
  with check (id=(select auth.uid()) and not (select magistore.is_admin()));
create policy categories_read on categories for select to authenticated using (true);
create policy categories_manage on categories for all to authenticated
  using ((select magistore.is_admin())) with check ((select magistore.is_admin()));
create policy products_read on products for select to authenticated using (true);
create policy products_manage on products for all to authenticated
  using ((select magistore.is_admin())) with check ((select magistore.is_admin()));
create policy orders_read on orders for select to authenticated
  using (user_id=(select auth.uid()) or (select magistore.is_admin()));
create policy order_status_admin on orders for update to authenticated
  using ((select magistore.is_admin())) with check ((select magistore.is_admin()));
create policy order_items_read on order_items for select to authenticated
  using ((select magistore.is_admin()) or exists (
    select 1 from magistore.orders o where o.id=order_id and o.user_id=(select auth.uid())
  ));

-- Only IDs + quantities cross the trust boundary. Locks are taken in ID order.
create function magistore.checkout(p_items jsonb, p_request_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid(); oid bigint; amount numeric(18,2) := 0;
  entry record; prod magistore.products%rowtype;
begin
  if uid is null or not exists (select 1 from magistore.profiles p join magistore.roles r
    on r.id=p.role_id where p.id=uid and r.role='customer') then
    raise exception 'Only customers can place an order.' using errcode='42501';
  end if;
  if p_request_id is null then raise exception 'Missing checkout reference.'; end if;
  perform pg_advisory_xact_lock(hashtextextended(uid::text || p_request_id::text, 0));
  select id,total into oid,amount from magistore.orders where user_id=uid and request_id=p_request_id;
  if found then return jsonb_build_object('id',oid,'total',amount); end if;
  if jsonb_typeof(p_items) is distinct from 'array' then raise exception 'Send a bag of items.'; end if;
  if jsonb_array_length(p_items) not between 1 and 100 then raise exception 'Choose between 1 and 100 different products.'; end if;
  if exists(select 1 from jsonb_array_elements(p_items) x where jsonb_typeof(x) <> 'object'
     or jsonb_typeof(x->'product_id') is distinct from 'number' or jsonb_typeof(x->'quantity') is distinct from 'number'
     or (x->>'product_id') !~ '^[1-9][0-9]{0,17}$' or (x->>'quantity') !~ '^[1-9][0-9]{0,6}$')
    then raise exception 'Each item needs a valid product and positive whole quantity.'; end if;
  if exists(select 1 from jsonb_to_recordset(p_items) as t(product_id bigint) group by product_id having count(*)>1)
    then raise exception 'Duplicate product in bag.'; end if;
  insert into magistore.orders(user_id,status,request_id) values(uid,'done',p_request_id) returning id into oid;
  amount := 0;
  for entry in select * from jsonb_to_recordset(p_items) as t(product_id bigint,quantity int) order by product_id loop
    select * into prod from magistore.products where id=entry.product_id for update;
    if not found then raise exception 'An item is no longer in the catalog. Review your bag.'; end if;
    if prod.stock < entry.quantity then raise exception 'Only % left for %. Review your bag.',prod.stock,prod.name; end if;
    update magistore.products set stock=stock-entry.quantity where id=prod.id;
    insert into magistore.order_items(order_id,product_id,product_name,unit_price,quantity)
      values(oid,prod.id,prod.name,prod.price,entry.quantity);
    amount := amount+prod.price*entry.quantity;
  end loop;
  update magistore.orders set total=amount where id=oid;
  return jsonb_build_object('id',oid,'total',amount);
end $$;
revoke all on all functions in schema magistore from public,anon,authenticated;
grant execute on function magistore.is_admin(), magistore.checkout(jsonb,uuid) to authenticated;

-- This bucket contains catalog photos only; public image URLs can be displayed by Flutter.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('magistore-products','magistore-products',true,5242880,array['image/jpeg','image/png','image/webp']);
create policy magistore_photo_upload on storage.objects for insert to authenticated
  with check (bucket_id='magistore-products' and (select magistore.is_admin()));
create policy magistore_photo_admin_read on storage.objects for select to authenticated
  using (bucket_id='magistore-products' and (select magistore.is_admin()));
create policy magistore_photo_remove on storage.objects for delete to authenticated
  using (bucket_id='magistore-products' and (select magistore.is_admin()));
-- Existing permissive policies for other buckets must not open writes to this one.
create policy magistore_photo_insert_guard on storage.objects as restrictive for insert to authenticated
  with check (bucket_id <> 'magistore-products' or (select magistore.is_admin()));
create policy magistore_photo_update_guard on storage.objects as restrictive for update to public
  using (bucket_id <> 'magistore-products') with check (bucket_id <> 'magistore-products');
create policy magistore_photo_delete_guard on storage.objects as restrictive for delete to authenticated
  using (bucket_id <> 'magistore-products' or (select magistore.is_admin()));
create policy magistore_photo_anon_insert_guard on storage.objects as restrictive for insert to anon
  with check (bucket_id <> 'magistore-products');
create policy magistore_photo_anon_delete_guard on storage.objects as restrictive for delete to anon
  using (bucket_id <> 'magistore-products');
notify pgrst,'reload schema';
commit;
