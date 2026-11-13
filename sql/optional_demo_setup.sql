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

drop policy if exists shop_read_products on public.products;
create policy shop_read_products on public.products
  for select to anon, authenticated using (true);

-- Run catalog_auth.sql to enable manager-only writes.
-- Add sample items with carltronics_sample_products.sql.
