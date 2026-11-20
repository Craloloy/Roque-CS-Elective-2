-- Run in a disposable test database. Rolls back all fixtures.
begin;
create function pg_temp.check_it(ok boolean, label text) returns void language plpgsql
as $$ begin if ok is distinct from true then raise exception 'Failed: %',label; end if; end $$;
create function pg_temp.expect_state(stmt text, expected text) returns void language plpgsql
as $$
declare actual text;
begin
  begin execute stmt; exception when others then get stacked diagnostics actual=returned_sqlstate; end;
  if actual is distinct from expected then raise exception 'Expected %, got %',expected,actual; end if;
end $$;

insert into auth.users(id,email,raw_user_meta_data) values
 ('20000000-0000-4000-8000-000000000001','pickup-a@example.test','{}'),
 ('20000000-0000-4000-8000-000000000002','pickup-b@example.test','{}');
insert into magistore.orders(id,user_id,status,request_id) overriding system value values
 (900010,'20000000-0000-4000-8000-000000000001','done','20000000-0000-4000-8000-000000000003');

set local role authenticated;
select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000001',true);
select pg_temp.expect_state('select magistore.confirm_pickup(900010)','P0001');
select pg_temp.expect_state('select * from magistore.take_pickup_email_jobs()','42883');
reset role;

update magistore.orders set status='ready' where id=900010;

set local role authenticated;
select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000002',true);
select pg_temp.expect_state('select magistore.confirm_pickup(900010)','P0001');
select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000001',true);
select magistore.confirm_pickup(900010);
select magistore.confirm_pickup(900010);
select pg_temp.check_it((select status='collected' from magistore.orders where id=900010),
 'owner can confirm ready order and safely retry');
reset role;
select pg_temp.check_it(
  to_regclass('magistore.pickup_email_jobs') is null,
  'pickup confirmation works without an email queue'
);
rollback;
