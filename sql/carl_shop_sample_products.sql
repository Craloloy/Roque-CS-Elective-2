-- Run after optional_demo_setup.sql if your products table does not exist yet.
-- Adds sample products without deleting existing rows or changing policies.
-- Images reuse the product assets already bundled with the Flutter app.
insert into public.products (name, price, image_url)
select sample.name, sample.price, sample.image_url
from (values
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
) as sample(name, price, image_url)
where not exists (
  select 1 from public.products existing where existing.name = sample.name
);
