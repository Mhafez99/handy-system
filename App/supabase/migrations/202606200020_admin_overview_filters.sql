drop function if exists public.admin_overview_stats();
drop function if exists public.admin_list_recent_requests(integer);

create or replace function public.admin_overview_stats(
  p_from timestamptz default null,
  p_to timestamptz default null
)
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
    'total_requests', (
      select count(*)::int
      from public.service_requests sr
      where (p_from is null or sr.created_at >= p_from)
        and (p_to is null or sr.created_at <= p_to)
    ),
    'requests_today', (
      select count(*)::int
      from public.service_requests
      where created_at >= date_trunc('day', timezone('utc', now()))
    ),
    'completed_requests', (
      select count(*)::int
      from public.service_requests sr
      where sr.status = 'completed'
        and (p_from is null or sr.created_at >= p_from)
        and (p_to is null or sr.created_at <= p_to)
    ),
    'active_requests', (
      select count(*)::int
      from public.service_requests sr
      where sr.status in (
        'new',
        'offered',
        'accepted',
        'on_the_way',
        'in_progress'
      )
        and (p_from is null or sr.created_at >= p_from)
        and (p_to is null or sr.created_at <= p_to)
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
    'offers_in_period', (
      select count(*)::int
      from public.offers o
      where (p_from is null or o.created_at >= p_from)
        and (p_to is null or o.created_at <= p_to)
    ),
    'status_counts', (
      select coalesce(jsonb_object_agg(status, status_count), '{}'::jsonb)
      from (
        select sr.status, count(*)::int as status_count
        from public.service_requests sr
        where (p_from is null or sr.created_at >= p_from)
          and (p_to is null or sr.created_at <= p_to)
        group by sr.status
      ) grouped_statuses
    ),
    'is_filtered', (p_from is not null or p_to is not null)
  )
  into result;

  return result;
end;
$$;

create or replace function public.admin_overview_daily_trend(
  p_from timestamptz default null,
  p_to timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from timestamptz;
  v_to timestamptz;
  result jsonb;
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  v_from := coalesce(
    p_from,
    date_trunc('day', timezone('utc', now()) - interval '29 days')
  );
  v_to := coalesce(
    p_to,
    date_trunc('day', timezone('utc', now())) + interval '1 day' - interval '1 microsecond'
  );

  if v_from > v_to then
    raise exception 'Invalid date range';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'day', series.day,
        'total', coalesce(counts.total, 0),
        'completed', coalesce(counts.completed, 0)
      )
      order by series.day
    ),
    '[]'::jsonb
  )
  into result
  from (
    select gs.day::date as day
    from generate_series(
      date_trunc('day', v_from)::date,
      date_trunc('day', v_to)::date,
      interval '1 day'
    ) as gs(day)
  ) series
  left join (
    select
      date_trunc('day', sr.created_at)::date as day,
      count(*)::int as total,
      count(*) filter (where sr.status = 'completed')::int as completed
    from public.service_requests sr
    where sr.created_at >= v_from
      and sr.created_at <= v_to
    group by 1
  ) counts on counts.day = series.day;

  return result;
end;
$$;

create or replace function public.admin_list_recent_requests(
  p_limit integer default 20,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_status text default null
)
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
  where (p_from is null or sr.created_at >= p_from)
    and (p_to is null or sr.created_at <= p_to)
    and (p_status is null or sr.status = p_status)
  order by sr.created_at desc
  limit greatest(least(coalesce(p_limit, 20), 50), 1);
end;
$$;

revoke all on function public.admin_overview_stats(timestamptz, timestamptz) from public;
revoke all on function public.admin_overview_daily_trend(timestamptz, timestamptz) from public;
revoke all on function public.admin_list_recent_requests(integer, timestamptz, timestamptz, text) from public;
grant execute on function public.admin_overview_stats(timestamptz, timestamptz) to authenticated;
grant execute on function public.admin_overview_daily_trend(timestamptz, timestamptz) to authenticated;
grant execute on function public.admin_list_recent_requests(integer, timestamptz, timestamptz, text) to authenticated;
