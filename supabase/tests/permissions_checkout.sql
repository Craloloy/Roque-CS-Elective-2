-- Run against a disposable test database after all migrations. No fixture is committed.
begin;
set local search_path = magistore,public,pg_catalog;
create function pg_temp.check_it(ok boolean, label text) returns void language plpgsql as $$
begin if ok is distinct from true then raise exception 'Failed: %',label; end if; end $$;
create function pg_temp.expect_state(stmt text, expected text) returns void language plpgsql as $$
declare actual text;
begin
  begin execute stmt; exception when others then get stacked diagnostics actual=returned_sqlstate; end;
  if actual is null or not (actual=any(string_to_array(expected,','))) then raise exception 'Expected SQLSTATE %, got % for %',expected,actual,stmt; end if;
end $$;

insert into auth.users(id,email,raw_user_meta_data) values
 ('10000000-0000-4000-8000-000000000001','magis-test-a@example.test','{"firstname":"Anna","role":"admin"}'),
 ('10000000-0000-4000-8000-000000000002','magis-test-b@example.test','{}'),
 ('10000000-0000-4000-8000-000000000003','magis-test-c@example.test','{}');
update profiles set role_id=(select id from roles where role='admin') where id='10000000-0000-4000-8000-000000000003';
insert into categories(name) values('Test department');
insert into products(id,name,stock,image_url,category_id,price) overriding system value values
 (900001,'Test grid pad',5,'image',(select id from categories where name='Test department'),50.25),
 (900002,'Test pen',0,'image',(select id from categories where name='Test department'),11.00);

-- Simulate an old broad object policy for a different project activity.
create policy magistore_test_older_insert on storage.objects for insert to authenticated with check(true);
set local role anon;
select pg_temp.expect_state(format('select * from magistore.%I', table_name),'42501')
from unnest(array['roles','profiles','categories','products','orders','order_items']) as t(table_name);
select pg_temp.expect_state($s$ select magistore.checkout('[]','30000000-0000-4000-8000-000000000001') $s$,'42501');
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
select pg_temp.check_it(not magistore.is_admin(),'signup ignores role metadata');
select pg_temp.expect_state($s$insert into storage.objects(bucket_id,name) values('magistore-products','customer-photo.jpg')$s$,'42501');
select pg_temp.check_it((select count(*)=1 from profiles),'customer reads only own profile');
update profiles set firstname='Updated' where id=auth.uid();
select pg_temp.check_it((select firstname='Updated' from profiles),'customer can update own name');
select pg_temp.expect_state('update magistore.profiles set role_id=2','42501');
select pg_temp.expect_state($s$insert into magistore.categories(name) values('Forbidden')$s$,'42501');
select pg_temp.expect_state($s$insert into magistore.products(name,description,price,stock,image_url,category_id) values('Forbidden','',1,1,'p',1)$s$,'42501');
update products set stock=50 where id=900001;
delete from products where id=900001;
select pg_temp.check_it((select stock=5 from products where id=900001),'customer cannot edit or delete a product');
select pg_temp.expect_state($s$insert into magistore.orders(user_id,total,status) values(auth.uid(),0,'done')$s$,'42501');
select pg_temp.expect_state('insert into magistore.order_items(order_id,product_id,product_name,unit_price,quantity) values(1,900001,''Forged'',0,1)','42501');
select pg_temp.expect_state($s$select magistore.checkout('[{"product_id":900001,"quantity":1},{"product_id":900002,"quantity":1}]','30000000-0000-4000-8000-000000000001')$s$,'P0001');
select pg_temp.check_it((select stock=5 from products where id=900001) and not exists(select 1 from orders) and not exists(select 1 from order_items),'late failure rolls back header, items and stock');
select pg_temp.expect_state($s$select magistore.checkout('[{"product_id":900001,"quantity":0}]','30000000-0000-4000-8000-000000000001')$s$,'P0001');
select pg_temp.expect_state($s$select magistore.checkout('[{"product_id":900001,"quantity":1},{"product_id":900001,"quantity":1}]','30000000-0000-4000-8000-000000000001')$s$,'P0001');
select magistore.checkout('[{"product_id":900001,"quantity":2,"unit_price":0,"product_name":"Wrong"}]','30000000-0000-4000-8000-000000000002');
select magistore.checkout('[{"product_id":900001,"quantity":2}]','30000000-0000-4000-8000-000000000002');
select pg_temp.check_it((select count(*)=1 and min(total)=100.50 and min(status)='done' from orders) and (select stock=3 from products where id=900001),'one authoritative order on retry');
update orders set status='collected';
select pg_temp.check_it((select status='done' from orders),'customer cannot update status');
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',true);
select pg_temp.check_it(not exists(select 1 from orders) and not exists(select 1 from order_items),'second customer cannot see first receipt');
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',true);
select pg_temp.check_it(magistore.is_admin() and (select count(*)>=3 from profiles),'admin reads profiles');
insert into storage.objects(bucket_id,name) values('magistore-products','staff-photo.jpg');
insert into products(name,description,price,stock,image_url,category_id)
  values('Admin product','Test',0,0,'image',(select id from categories where name='Test department'));
select pg_temp.check_it(
  (select price=0 and stock=0 from products where name='Admin product'),
  'admin can add a product with zero price and stock'
);
delete from products where name='Admin product';
update profiles set firstname='Overwritten' where id='10000000-0000-4000-8000-000000000001';
select pg_temp.check_it(
  (select firstname='Updated' from profiles where id='10000000-0000-4000-8000-000000000001'),
  'admin cannot edit customer profiles'
);
select pg_temp.expect_state($s$select magistore.checkout('[{"product_id":900001,"quantity":1}]','30000000-0000-4000-8000-000000000003')$s$,'42501');
select pg_temp.expect_state('update magistore.orders set total=1','42501');
update orders set status='ready' where user_id='10000000-0000-4000-8000-000000000001';
select pg_temp.check_it((select status='ready' from orders where user_id='10000000-0000-4000-8000-000000000001'),'admin can update status');
update products set price=25,name='Renamed' where id=900001;
delete from products where id=900001;
select pg_temp.check_it((select product_id is null and product_name='Test grid pad' and unit_price=50.25 and quantity=2 from order_items where product_name='Test grid pad'),'receipt survives product edits and deletion');
select pg_temp.expect_state($s$delete from magistore.categories where name='Test department'$s$,'23001,23503');
insert into categories(name) values('New category');
update categories set name='Renamed category' where name='New category';
delete from categories where name='Renamed category';
select pg_temp.check_it(not exists(select 1 from categories where name in ('New category','Renamed category')),'admin category CRUD');
reset role;
insert into products(id,name,stock,image_url,category_id,price) overriding system value values
 (900003,'Test uniform',3,'image',(select id from categories where name='PE Uniforms'),850);
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
select pg_temp.expect_state($s$select magistore.checkout('[{"product_id":900003,"quantity":1}]','30000000-0000-4000-8000-000000000004')$s$,'P0001');
select pg_temp.expect_state($s$select magistore.checkout('[{"product_id":900003,"quantity":2,"size":"S"},{"product_id":900003,"quantity":2,"size":"M"}]','30000000-0000-4000-8000-000000000004')$s$,'P0001');
select pg_temp.check_it((select stock=3 from products where id=900003),'mixed sizes share stock and overselling rolls back');
select magistore.checkout('[{"product_id":900003,"quantity":1,"size":"S"},{"product_id":900003,"quantity":2,"size":"M"}]','30000000-0000-4000-8000-000000000004');
select pg_temp.check_it(
  (select count(*)=2 and sum(quantity)=3 and count(distinct size)=2 from order_items where product_id=900003)
  and (select stock=0 from products where id=900003),'different sizes remain separate on the receipt');
rollback;
