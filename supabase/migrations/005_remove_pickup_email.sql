-- Only removes the earlier pickup email integration. Keep in-app pickup confirmation.
begin;
do $$
declare
  job_id bigint;
begin
  if to_regclass('cron.job') is not null then
    for job_id in
      select jobid from cron.job where jobname = 'magistore-pickup-emails'
    loop
      perform cron.unschedule(job_id);
    end loop;
  end if;
end;
$$;
drop trigger if exists magistore_queue_pickup_email on magistore.orders;
drop function if exists magistore.queue_pickup_email();
drop function if exists magistore.take_pickup_email_jobs();
drop table if exists magistore.pickup_email_jobs;
notify pgrst, 'reload schema';
commit;
