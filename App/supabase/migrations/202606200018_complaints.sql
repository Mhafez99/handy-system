create table if not exists public.service_complaints (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.service_requests(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  worker_id uuid not null references public.profiles(id) on delete cascade,
  category text not null check (
    category in ('poor_quality', 'no_show', 'overcharge', 'behavior', 'other')
  ),
  description text not null check (char_length(trim(description)) between 10 and 1000),
  status text not null default 'open' check (
    status in ('open', 'in_review', 'resolved', 'dismissed')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.service_complaints enable row level security;

revoke all on table public.service_complaints from anon, authenticated;
grant select on table public.service_complaints to authenticated;

create policy "Customers can read their own service complaints"
on public.service_complaints for select
to authenticated
using ((select auth.uid()) = customer_id);

create policy "Workers can read complaints filed against them"
on public.service_complaints for select
to authenticated
using ((select auth.uid()) = worker_id);

create or replace function public.submit_service_complaint(
  p_request_id uuid,
  p_category text,
  p_description text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_worker_id uuid;
  trimmed_description text;
begin
  trimmed_description := trim(coalesce(p_description, ''));

  if p_category not in ('poor_quality', 'no_show', 'overcharge', 'behavior', 'other') then
    raise exception 'Invalid complaint category';
  end if;

  if char_length(trimmed_description) < 10 then
    raise exception 'Complaint description is too short';
  end if;

  select o.worker_id
  into selected_worker_id
  from public.service_requests sr
  join public.offers o on o.request_id = sr.id
  where sr.id = p_request_id
    and sr.customer_id = (select auth.uid())
    and sr.status = 'completed'
    and o.status = 'accepted';

  if selected_worker_id is null then
    raise exception 'Request is not available for complaint';
  end if;

  insert into public.service_complaints (
    request_id,
    customer_id,
    worker_id,
    category,
    description
  )
  values (
    p_request_id,
    (select auth.uid()),
    selected_worker_id,
    p_category,
    trimmed_description
  );

  update public.service_requests
  set status = 'complaint',
      updated_at = now()
  where id = p_request_id;
end;
$$;

create or replace function public.admin_list_complaints()
returns table (
  id uuid,
  request_id uuid,
  category text,
  description text,
  status text,
  created_at timestamptz,
  customer_name text,
  customer_phone text,
  worker_name text,
  worker_phone text,
  service_name text,
  area text
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
    c.id,
    c.request_id,
    c.category,
    c.description,
    c.status,
    c.created_at,
    customer.full_name as customer_name,
    customer.phone as customer_phone,
    worker.full_name as worker_name,
    worker.phone as worker_phone,
    service.name as service_name,
    sr.area
  from public.service_complaints c
  join public.service_requests sr on sr.id = c.request_id
  join public.profiles customer on customer.id = c.customer_id
  join public.profiles worker on worker.id = c.worker_id
  join public.services service on service.id = sr.service_id
  order by
    case c.status
      when 'open' then 0
      when 'in_review' then 1
      else 2
    end,
    c.created_at desc;
end;
$$;

create or replace function public.admin_update_complaint_status(
  p_complaint_id uuid,
  p_status text
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

  if p_status not in ('open', 'in_review', 'resolved', 'dismissed') then
    raise exception 'Invalid complaint status';
  end if;

  update public.service_complaints
  set status = p_status,
      updated_at = now()
  where id = p_complaint_id;

  if not found then
    raise exception 'Complaint was not found';
  end if;
end;
$$;

revoke all on function public.submit_service_complaint(uuid, text, text) from public;
grant execute on function public.submit_service_complaint(uuid, text, text) to authenticated;

revoke all on function public.admin_list_complaints() from public;
revoke all on function public.admin_update_complaint_status(uuid, text) from public;
grant execute on function public.admin_list_complaints() to authenticated;
grant execute on function public.admin_update_complaint_status(uuid, text) to authenticated;
