create or replace function public.admin_overview_stats()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  result jsonb;
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  select jsonb_build_object(
    'total_requests', (select count(*)::int from public.service_requests),
    'requests_today', (
      select count(*)::int
      from public.service_requests
      where created_at >= date_trunc('day', timezone('utc', now()))
    ),
    'completed_requests', (
      select count(*)::int
      from public.service_requests
      where status = 'completed'
    ),
    'active_requests', (
      select count(*)::int
      from public.service_requests
      where status in (
        'new',
        'offered',
        'accepted',
        'on_the_way',
        'in_progress'
      )
    ),
    'open_complaints', (
      select count(*)::int
      from public.service_complaints
      where status in ('open', 'in_review')
    ),
    'pending_workers', (
      select count(*)::int
      from public.profiles p
      join public.worker_profiles wp on wp.user_id = p.id
      where p.role = 'worker'
        and p.status = 'pending'
        and wp.approval_status = 'pending'
    ),
    'total_customers', (
      select count(*)::int from public.profiles where role = 'customer'
    ),
    'active_workers', (
      select count(*)::int
      from public.profiles
      where role = 'worker' and status = 'active'
    ),
    'total_offers', (select count(*)::int from public.offers),
    'status_counts', (
      select coalesce(jsonb_object_agg(status, status_count), '{}'::jsonb)
      from (
        select status, count(*)::int as status_count
        from public.service_requests
        group by status
      ) grouped_statuses
    )
  )
  into result;

  return result;
end;
$$;

create or replace function public.admin_list_recent_requests(p_limit integer default 20)
returns table (
  id uuid,
  status text,
  created_at timestamptz,
  area text,
  governorate text,
  service_name text,
  category_name text,
  customer_name text,
  worker_name text,
  offer_count bigint,
  final_price integer,
  payment_method text
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  return query
  select
    sr.id,
    sr.status,
    sr.created_at,
    sr.area,
    sr.governorate,
    service.name as service_name,
    category.name as category_name,
    customer.full_name as customer_name,
    coalesce(worker.full_name, '') as worker_name,
    (
      select count(*)
      from public.offers o
      where o.request_id = sr.id
    ) as offer_count,
    sr.final_price,
    sr.payment_method
  from public.service_requests sr
  join public.services service on service.id = sr.service_id
  join public.categories category on category.id = sr.category_id
  join public.profiles customer on customer.id = sr.customer_id
  left join lateral (
    select p.full_name
    from public.offers o
    join public.profiles p on p.id = o.worker_id
    where o.request_id = sr.id
      and o.status = 'accepted'
    limit 1
  ) worker on true
  order by sr.created_at desc
  limit greatest(least(coalesce(p_limit, 20), 50), 1);
end;
$$;

revoke all on function public.admin_overview_stats() from public;
revoke all on function public.admin_list_recent_requests(integer) from public;
grant execute on function public.admin_overview_stats() to authenticated;
grant execute on function public.admin_list_recent_requests(integer) to authenticated;
