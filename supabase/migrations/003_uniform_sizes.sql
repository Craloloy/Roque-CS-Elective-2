-- Run after 001 and 002. Existing order lines keep a null size.
begin;
alter table magistore.order_items
  add column size text check (size in ('XS','S','M','L','XL'));

create or replace function magistore.checkout(p_items jsonb, p_request_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid(); oid bigint; amount numeric(18,2) := 0;
  entry record; needs_size boolean; prod magistore.products%rowtype;
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
  if jsonb_array_length(p_items) not between 1 and 100 then raise exception 'Choose between 1 and 100 bag lines.'; end if;
  if exists(select 1 from jsonb_array_elements(p_items) x where jsonb_typeof(x) <> 'object'
     or jsonb_typeof(x->'product_id') is distinct from 'number' or jsonb_typeof(x->'quantity') is distinct from 'number'
     or (x ? 'size' and jsonb_typeof(x->'size') is distinct from 'string')
     or (x->>'product_id') !~ '^[1-9][0-9]{0,17}$' or (x->>'quantity') !~ '^[1-9][0-9]{0,6}$')
    then raise exception 'Each item needs a valid product and positive whole quantity.'; end if;
  if exists(select 1 from jsonb_to_recordset(p_items) as t(product_id bigint,size text) group by product_id,size having count(*)>1)
    then raise exception 'Duplicate product and size in bag.'; end if;
  insert into magistore.orders(user_id,status,request_id) values(uid,'done',p_request_id) returning id into oid;
  amount := 0;
  for entry in select * from jsonb_to_recordset(p_items) as t(product_id bigint,quantity int,size text) order by product_id,size loop
    select * into prod from magistore.products where id=entry.product_id for update;
    if not found then raise exception 'An item is no longer in the catalog. Review your bag.'; end if;
    select lower(btrim(c.name)) = 'pe uniforms' into needs_size
      from magistore.categories c where c.id=prod.category_id;
    if needs_size and (entry.size is null or entry.size not in ('XS','S','M','L','XL')) then
      raise exception 'Select a valid uniform size for %.', prod.name;
    elsif not needs_size and entry.size is not null then
      raise exception 'This product does not have sizes: %.', prod.name;
    end if;
    if prod.stock < entry.quantity then raise exception 'Only % left for %. Review your bag.',prod.stock,prod.name; end if;
    update magistore.products set stock=stock-entry.quantity where id=prod.id;
    insert into magistore.order_items(order_id,product_id,product_name,unit_price,quantity,size)
      values(oid,prod.id,prod.name,prod.price,entry.quantity,entry.size);
    amount := amount+prod.price*entry.quantity;
  end loop;
  update magistore.orders set total=amount where id=oid;
  return jsonb_build_object('id',oid,'total',amount);
end $$;
commit;
