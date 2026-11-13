-- Carltronics demo catalog. Prices are illustrative, not live retail quotes.
-- Use optional_demo_setup.sql first if public.products does not exist.
-- The app renders generic laptop illustrations for carltronics:// image URIs.
begin;

-- Remove only unchanged merchandise inserted by the previous demo seed.
delete from public.products existing
using (values
('Everyday Campus Tee',        249.00, 'assets/products/shirt.png'),
  ('Computer Science Tee',       299.00, 'assets/products/cs.png'),
  ('Classic Campus Uniform',     799.00, 'assets/products/uniform.png'),
  ('Daily Essentials Sling Bag', 349.00, 'assets/products/sling.png'),
  ('Campus Phone Case',          159.00, 'assets/products/case.png'),
  ('Signature Enamel Pin',        89.00, 'assets/products/pin.png'),
  ('Caduceus Pin',               129.00, 'assets/products/caduceus.png'),
  ('Campus Ribbon',               49.00, 'assets/products/ribbon.png'),
  ('Everyday Tee Duo',           459.00, 'assets/products/shirt.png'),
  ('CS Tee Duo',                 549.00, 'assets/products/cs.png'),
  ('Uniform Set of Two',        1499.00, 'assets/products/uniform.png'),
  ('Sling Bag Duo',              649.00, 'assets/products/sling.png'),
  ('Phone Case Duo',             289.00, 'assets/products/case.png'),
  ('Enamel Pin Set of Three',    239.00, 'assets/products/pin.png'),
  ('Caduceus Pin Duo',           229.00, 'assets/products/caduceus.png'),
  ('Ribbon Set of Five',         199.00, 'assets/products/ribbon.png')
) as old_demo(name, price, image_url)
where existing.name = old_demo.name
  and existing.price = old_demo.price
  and existing.image_url = old_demo.image_url;

-- Remove the exact numbered placeholders from the original demo setup.
delete from public.products
where name ~ '^Campus item ([1-9]|1[0-9]|20)$'
  and price = substring(name from '[0-9]+$')::numeric * 25
  and image_url is null;

-- Skip laptops that already exist; rerunning will not duplicate the catalog.
insert into public.products (name, price, image_url)
select sample.name, sample.price, sample.image_url
from (values
  ('Lenovo V14', 19995.00, 'carltronics://laptop/student'),
  ('Acer Aspire Lite', 21995.00, 'carltronics://laptop/student'),
  ('ASUS Vivobook Go 15', 22995.00, 'carltronics://laptop/student'),
  ('HP Laptop 14', 26995.00, 'carltronics://laptop/student'),
  ('Acer Aspire 3', 24995.00, 'carltronics://laptop/office'),
  ('Lenovo IdeaPad Slim 3', 27995.00, 'carltronics://laptop/office'),
  ('ASUS Vivobook 15', 32995.00, 'carltronics://laptop/office'),
  ('Dell Inspiron 15', 38995.00, 'carltronics://laptop/office'),
  ('HP Pavilion Aero 13', 49995.00, 'carltronics://laptop/ultrabook'),
  ('Acer Swift Go 14', 54995.00, 'carltronics://laptop/ultrabook'),
  ('ASUS Zenbook 14', 59995.00, 'carltronics://laptop/ultrabook'),
  ('Lenovo Yoga Slim 7', 64995.00, 'carltronics://laptop/ultrabook'),
  ('Acer Nitro V 15', 47995.00, 'carltronics://laptop/gaming'),
  ('HP Victus 15', 52995.00, 'carltronics://laptop/gaming'),
  ('ASUS TUF Gaming A15', 56995.00, 'carltronics://laptop/gaming'),
  ('Lenovo LOQ 15', 62995.00, 'carltronics://laptop/gaming'),
  ('ASUS ROG Zephyrus G14', 109995.00, 'carltronics://laptop/gaming'),
  ('Lenovo Yoga Pro 9i', 139995.00, 'carltronics://laptop/creator'),
  ('ASUS ProArt P16', 149995.00, 'carltronics://laptop/creator'),
  ('Dell XPS 16', 159995.00, 'carltronics://laptop/creator')
) as sample(name, price, image_url)
where not exists (
  select 1 from public.products existing where existing.name = sample.name
);

commit;
