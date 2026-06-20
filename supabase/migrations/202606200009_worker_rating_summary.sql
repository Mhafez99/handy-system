create or replace function public.worker_rating_summary(p_worker_ids uuid[])
returns table (
  worker_id uuid,
  average_rating numeric,
  review_count bigint
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  return query
  select
    sr.worker_id,
    round(avg(sr.rating)::numeric, 1) as average_rating,
    count(*)::bigint as review_count
  from public.service_reviews sr
  where sr.worker_id = any(p_worker_ids)
  group by sr.worker_id;
end;
$$;

revoke all on function public.worker_rating_summary(uuid[]) from public;
grant execute on function public.worker_rating_summary(uuid[]) to authenticated;
