alter table public.service_requests
  drop constraint if exists service_requests_status_check;

alter table public.service_requests
  add constraint service_requests_status_check
  check (
    status in (
      'new',
      'offered',
      'accepted',
      'on_the_way',
      'in_progress',
      'completed',
      'cancelled',
      'complaint'
    )
  );

create or replace function public.mark_on_the_way(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.service_requests sr
  set status = 'on_the_way',
      updated_at = now()
  where sr.id = p_request_id
    and sr.status = 'accepted'
    and exists (
      select 1
      from public.offers o
      where o.request_id = sr.id
        and o.worker_id = (select auth.uid())
        and o.status = 'accepted'
    );

  if not found then
    raise exception 'Request is not available to mark on the way';
  end if;
end;
$$;

create or replace function public.start_work(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.service_requests sr
  set status = 'in_progress',
      updated_at = now()
  where sr.id = p_request_id
    and sr.status = 'on_the_way'
    and exists (
      select 1
      from public.offers o
      where o.request_id = sr.id
        and o.worker_id = (select auth.uid())
        and o.status = 'accepted'
    );

  if not found then
    raise exception 'Request is not available to start';
  end if;
end;
$$;

drop policy if exists "Accepted workers can read accepted requests"
on public.service_requests;

create policy "Accepted workers can read accepted requests"
on public.service_requests for select
to authenticated
using (
  status in ('accepted', 'on_the_way', 'in_progress', 'completed')
  and exists (
    select 1
    from public.offers o
    where o.request_id = service_requests.id
      and o.worker_id = (select auth.uid())
      and o.status = 'accepted'
  )
);

drop policy if exists "Accepted workers can read customer profiles"
on public.profiles;

create policy "Accepted workers can read customer profiles"
on public.profiles for select
to authenticated
using (
  exists (
    select 1
    from public.service_requests sr
    join public.offers o on o.request_id = sr.id
    where sr.customer_id = profiles.id
      and sr.status in ('accepted', 'on_the_way', 'in_progress', 'completed')
      and o.worker_id = (select auth.uid())
      and o.status = 'accepted'
  )
);

revoke all on function public.mark_on_the_way(uuid) from public;
grant execute on function public.mark_on_the_way(uuid) to authenticated;
