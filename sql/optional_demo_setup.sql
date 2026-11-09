-- Optional: use in a NEW/demo Supabase project if you do not have products yet.
-- Existing shop? Keep its table and policies, and adapt product_repository.dart.
create table if not exists public.products (
  id bigint generated always as identity primary key,
  name text not null,
  price numeric(12, 2) not null check (price >= 0),
  image_url text
);

create index if not exists products_price_id_idx on public.products (price, id);
alter table public.products enable row level security;
grant select on public.products to anon, authenticated;

do $$
begin
  if not exists (select 1 from pg_policies
      where schemaname = 'public' and tablename = 'products'
      and policyname = 'shop_read_products') then
    create policy shop_read_products on public.products
      for select to anon, authenticated using (true);
  end if;
end $$;

-- Add sample items with sql/carltronics_sample_products.sql.

-- This example deliberately grants SELECT only. Keep your existing properly
-- scoped authentication and RLS policies for create/update/delete operations.
