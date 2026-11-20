begin;

-- Students can confirm only their own ready orders. Keep the existing admin policy.
create or replace function magistore.confirm_pickup(p_order_id bigint)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null or magistore.is_admin() then
    raise exception 'Only students can confirm their pickup.' using errcode = '42501';
  end if;

  update magistore.orders
  set status = 'collected'
  where id = p_order_id and user_id = v_user and status = 'ready';
  if not found and not exists (
    select 1 from magistore.orders
    where id = p_order_id and user_id = v_user and status = 'collected'
  ) then
    raise exception 'This order is not available to confirm.';
  end if;
end;
$$;
revoke all on function magistore.confirm_pickup(bigint) from public, anon, authenticated;
grant execute on function magistore.confirm_pickup(bigint) to authenticated;

notify pgrst, 'reload schema';
commit;
