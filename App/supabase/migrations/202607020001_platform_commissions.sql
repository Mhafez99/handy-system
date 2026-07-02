-- Platform monetization: global + per-category commission, and a commission ledger.
-- Commission is DEDUCTED from the worker payout: the customer pays final_price,
-- the platform keeps commission_amount, the worker receives net_amount.

-- 1) Global platform settings (singleton row id = 1)
create table if not exists public.platform_settings (
  id smallint primary key default 1 check (id = 1),
  default_commission_rate numeric(5, 4) not null default 0.10
    check (default_commission_rate >= 0 and default_commission_rate <= 1),
  min_order_price integer not null default 0 check (min_order_price >= 0),
  updated_at timestamptz not null default now()
);

insert into public.platform_settings (id)
values (1)
on conflict (id) do nothing;

-- 2) Optional per-category commission override (null => use global default)
alter table public.categories
  add column if not exists commission_rate numeric(5, 4)
    check (commission_rate is null or (commission_rate >= 0 and commission_rate <= 1));

-- 3) Commission ledger: one snapshot row per completed request
create table if not exists public.platform_commissions (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique
    references public.service_requests(id) on delete cascade,
  worker_id uuid references public.profiles(id) on delete set null,
  category_id bigint references public.categories(id) on delete set null,
  gross_amount integer not null check (gross_amount >= 0),
  commission_rate numeric(5, 4) not null,
  commission_amount integer not null check (commission_amount >= 0),
  net_amount integer not null,
  created_at timestamptz not null default now()
);

create index if not exists platform_commissions_worker_idx
  on public.platform_commissions (worker_id);
create index if not exists platform_commissions_created_idx
  on public.platform_commissions (created_at);
create index if not exists platform_commissions_category_idx
  on public.platform_commissions (category_id);

alter table public.platform_settings enable row level security;
alter table public.platform_commissions enable row level security;

revoke all on table public.platform_settings from anon, authenticated;
revoke all on table public.platform_commissions from anon, authenticated;

-- 4) Trigger: snapshot commission when a request becomes 'completed'
create or replace function public.record_platform_commission()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rate numeric(5, 4);
  v_worker uuid;
  v_commission integer;
begin
  if new.status = 'completed'
     and (old.status is distinct from 'completed')
     and new.final_price is not null then

    select coalesce(c.commission_rate, s.default_commission_rate, 0)
    into v_rate
    from public.platform_settings s
    left join public.categories c on c.id = new.category_id
    where s.id = 1;

    v_rate := coalesce(v_rate, 0);

    select o.worker_id
    into v_worker
    from public.offers o
    where o.request_id = new.id
      and o.status = 'accepted'
    limit 1;

    v_commission := round(new.final_price * v_rate);

    insert into public.platform_commissions (
      request_id, worker_id, category_id, gross_amount,
      commission_rate, commission_amount, net_amount
    )
    values (
      new.id, v_worker, new.category_id, new.final_price,
      v_rate, v_commission, new.final_price - v_commission
    )
    on conflict (request_id) do update
      set worker_id = excluded.worker_id,
          category_id = excluded.category_id,
          gross_amount = excluded.gross_amount,
          commission_rate = excluded.commission_rate,
          commission_amount = excluded.commission_amount,
          net_amount = excluded.net_amount;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_record_platform_commission on public.service_requests;
create trigger trg_record_platform_commission
after update on public.service_requests
for each row
execute function public.record_platform_commission();

-- 5) Backfill ledger for requests already completed
insert into public.platform_commissions (
  request_id, worker_id, category_id, gross_amount,
  commission_rate, commission_amount, net_amount
)
select
  sr.id,
  accepted.worker_id,
  sr.category_id,
  sr.final_price,
  coalesce(c.commission_rate, s.default_commission_rate, 0) as rate,
  round(sr.final_price * coalesce(c.commission_rate, s.default_commission_rate, 0)) as commission,
  sr.final_price - round(sr.final_price * coalesce(c.commission_rate, s.default_commission_rate, 0)) as net
from public.service_requests sr
cross join public.platform_settings s
left join public.categories c on c.id = sr.category_id
left join lateral (
  select o.worker_id
  from public.offers o
  where o.request_id = sr.id
    and o.status = 'accepted'
  limit 1
) accepted on true
where sr.status = 'completed'
  and sr.final_price is not null
on conflict (request_id) do nothing;

-- 6) Admin RPCs (Supabase fallback parity with the backend endpoints)
create or replace function public.admin_get_settings()
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
    'default_commission_rate', s.default_commission_rate,
    'min_order_price', s.min_order_price,
    'updated_at', s.updated_at,
    'categories', (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'id', c.id,
            'name', c.name,
            'commission_rate', c.commission_rate
          )
          order by c.sort_order, c.name
        ),
        '[]'::jsonb
      )
      from public.categories c
    )
  )
  into result
  from public.platform_settings s
  where s.id = 1;

  return result;
end;
$$;

create or replace function public.admin_update_settings(
  p_default_commission_rate numeric,
  p_min_order_price integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  if p_default_commission_rate is null
     or p_default_commission_rate < 0
     or p_default_commission_rate > 1 then
    raise exception 'Commission rate must be between 0 and 1';
  end if;

  update public.platform_settings
  set default_commission_rate = p_default_commission_rate,
      min_order_price = greatest(coalesce(p_min_order_price, 0), 0),
      updated_at = now()
  where id = 1;
end;
$$;

create or replace function public.admin_update_category_commission(
  p_category_id bigint,
  p_commission_rate numeric
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  if p_commission_rate is not null
     and (p_commission_rate < 0 or p_commission_rate > 1) then
    raise exception 'Commission rate must be between 0 and 1';
  end if;

  update public.categories
  set commission_rate = p_commission_rate
  where id = p_category_id;

  if not found then
    raise exception 'Category was not found';
  end if;
end;
$$;

create or replace function public.admin_revenue_stats(
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
    'completed_count', coalesce(count(*), 0)::int,
    'total_gross', coalesce(sum(pc.gross_amount), 0)::bigint,
    'total_commission', coalesce(sum(pc.commission_amount), 0)::bigint,
    'total_net', coalesce(sum(pc.net_amount), 0)::bigint,
    'avg_order', coalesce(round(avg(pc.gross_amount)), 0)::int,
    'is_filtered', (p_from is not null or p_to is not null)
  )
  into result
  from public.platform_commissions pc
  where (p_from is null or pc.created_at >= p_from)
    and (p_to is null or pc.created_at <= p_to);

  return result;
end;
$$;

create or replace function public.admin_revenue_by_category(
  p_from timestamptz default null,
  p_to timestamptz default null
)
returns table (
  category_id bigint,
  category_name text,
  completed_count bigint,
  total_gross bigint,
  total_commission bigint,
  total_net bigint
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
    pc.category_id,
    coalesce(c.name, 'غير محدد') as category_name,
    count(*) as completed_count,
    sum(pc.gross_amount)::bigint as total_gross,
    sum(pc.commission_amount)::bigint as total_commission,
    sum(pc.net_amount)::bigint as total_net
  from public.platform_commissions pc
  left join public.categories c on c.id = pc.category_id
  where (p_from is null or pc.created_at >= p_from)
    and (p_to is null or pc.created_at <= p_to)
  group by pc.category_id, c.name
  order by total_commission desc;
end;
$$;

create or replace function public.admin_revenue_daily(
  p_from timestamptz default null,
  p_to timestamptz default null
)
returns table (
  day date,
  total_gross bigint,
  total_commission bigint,
  total_net bigint
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
    (pc.created_at at time zone 'utc')::date as day,
    sum(pc.gross_amount)::bigint,
    sum(pc.commission_amount)::bigint,
    sum(pc.net_amount)::bigint
  from public.platform_commissions pc
  where (p_from is null or pc.created_at >= p_from)
    and (p_to is null or pc.created_at <= p_to)
  group by day
  order by day;
end;
$$;

create or replace function public.admin_list_worker_payouts(
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_limit integer default 50
)
returns table (
  worker_id uuid,
  worker_name text,
  worker_phone text,
  jobs_count bigint,
  total_gross bigint,
  total_commission bigint,
  total_net bigint
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
    pc.worker_id,
    coalesce(p.full_name, 'غير محدد') as worker_name,
    coalesce(p.phone, '') as worker_phone,
    count(*) as jobs_count,
    sum(pc.gross_amount)::bigint as total_gross,
    sum(pc.commission_amount)::bigint as total_commission,
    sum(pc.net_amount)::bigint as total_net
  from public.platform_commissions pc
  left join public.profiles p on p.id = pc.worker_id
  where pc.worker_id is not null
    and (p_from is null or pc.created_at >= p_from)
    and (p_to is null or pc.created_at <= p_to)
  group by pc.worker_id, p.full_name, p.phone
  order by total_net desc
  limit greatest(least(coalesce(p_limit, 50), 200), 1);
end;
$$;

revoke all on function public.admin_get_settings() from public;
revoke all on function public.admin_update_settings(numeric, integer) from public;
revoke all on function public.admin_update_category_commission(bigint, numeric) from public;
revoke all on function public.admin_revenue_stats(timestamptz, timestamptz) from public;
revoke all on function public.admin_revenue_by_category(timestamptz, timestamptz) from public;
revoke all on function public.admin_revenue_daily(timestamptz, timestamptz) from public;
revoke all on function public.admin_list_worker_payouts(timestamptz, timestamptz, integer) from public;

grant execute on function public.admin_get_settings() to authenticated;
grant execute on function public.admin_update_settings(numeric, integer) to authenticated;
grant execute on function public.admin_update_category_commission(bigint, numeric) to authenticated;
grant execute on function public.admin_revenue_stats(timestamptz, timestamptz) to authenticated;
grant execute on function public.admin_revenue_by_category(timestamptz, timestamptz) to authenticated;
grant execute on function public.admin_revenue_daily(timestamptz, timestamptz) to authenticated;
grant execute on function public.admin_list_worker_payouts(timestamptz, timestamptz, integer) to authenticated;
