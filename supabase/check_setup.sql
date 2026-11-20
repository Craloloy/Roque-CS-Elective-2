-- Read-only checks for SQL Editor. No credentials or customer data in the results.
select schemaname, tablename, rowsecurity
from pg_tables where schemaname='magistore' order by tablename;
select name from magistore.categories order by name;
select count(*) as active_products from magistore.products;
select r.role, count(p.id) as profiles from magistore.roles r
left join magistore.profiles p on p.role_id=r.id group by r.role order by r.role;
select policyname,tablename,cmd,roles from pg_policies where schemaname='magistore' order by tablename,policyname;
select event_object_schema,event_object_table,trigger_name from information_schema.triggers
where trigger_name='magistore_on_auth_user_created';

select table_schema, table_name, column_name, data_type
from information_schema.columns
where table_schema='magistore' and table_name='order_items' and column_name='size';
select p.proname as function_name, pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef as security_definer
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='magistore' and p.proname in ('handle_new_user','is_admin','checkout')
order by p.proname;
