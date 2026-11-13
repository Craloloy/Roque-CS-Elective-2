-- Run in Supabase SQL Editor after the products table exists.
-- Browsing policies stay in place; only approved accounts may write.
begin;

create table if not exists public.apex_catalog_managers (
  user_id uuid primary key references auth.users(id) on delete cascade
);

alter table public.apex_catalog_managers enable row level security;
revoke all on public.apex_catalog_managers from public, anon, authenticated;
grant select on public.apex_catalog_managers to authenticated;

drop policy if exists apex_manager_read_own on public.apex_catalog_managers;
create policy apex_manager_read_own on public.apex_catalog_managers
  for select to authenticated using (user_id = (select auth.uid()));

alter table public.products enable row level security;
revoke insert, update, delete, truncate on public.products from public, anon;
revoke truncate on public.products from authenticated;
grant select, insert, update, delete on public.products to authenticated;

-- Grant identity sequence access only when the products table has one.
do $$
declare
  id_sequence text := pg_get_serial_sequence('public.products', 'id');
begin
  if id_sequence is not null then
    execute format('grant usage on sequence %s to authenticated', id_sequence);
  end if;
end $$;

drop policy if exists shop_insert_products on public.products;
drop policy if exists shop_update_products on public.products;
drop policy if exists shop_delete_products on public.products;

drop policy if exists apex_manager_access on public.products;
create policy apex_manager_access on public.products
  for all to authenticated
  using (exists (select 1 from public.apex_catalog_managers where user_id = (select auth.uid())))
  with check (exists (select 1 from public.apex_catalog_managers where user_id = (select auth.uid())));

-- Restrictive policies also guard against any older permissive write policies.
drop policy if exists apex_manager_insert on public.products;
create policy apex_manager_insert on public.products as restrictive
  for insert to authenticated
  with check (exists (select 1 from public.apex_catalog_managers where user_id = (select auth.uid())));

drop policy if exists apex_manager_update on public.products;
create policy apex_manager_update on public.products as restrictive
  for update to authenticated
  using (exists (select 1 from public.apex_catalog_managers where user_id = (select auth.uid())))
  with check (exists (select 1 from public.apex_catalog_managers where user_id = (select auth.uid())));

drop policy if exists apex_manager_delete on public.products;
create policy apex_manager_delete on public.products as restrictive
  for delete to authenticated
  using (exists (select 1 from public.apex_catalog_managers where user_id = (select auth.uid())));

commit;
