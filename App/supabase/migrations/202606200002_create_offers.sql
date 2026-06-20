create table if not exists public.offers (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.service_requests(id) on delete cascade,
  worker_id uuid not null constraint offers_worker_id_fkey references public.profiles(id) on delete cascade,
  price integer not null check (price > 0),
  arrival_time text not null check (char_length(trim(arrival_time)) >= 3),
  note text,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'withdrawn')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (request_id, worker_id)
);

alter table public.offers enable row level security;

revoke all on table public.offers from anon, authenticated;
grant select, insert on table public.offers to authenticated;

create policy "Customers can read offers on their own requests"
on public.offers for select
to authenticated
using (
  exists (
    select 1
    from public.service_requests sr
    where sr.id = offers.request_id
      and sr.customer_id = (select auth.uid())
  )
);

create policy "Workers can read their own offers"
on public.offers for select
to authenticated
using ((select auth.uid()) = worker_id);

create policy "Customers can read offering worker profiles"
on public.profiles for select
to authenticated
using (
  exists (
    select 1
    from public.offers o
    join public.service_requests sr on sr.id = o.request_id
    where o.worker_id = profiles.id
      and sr.customer_id = (select auth.uid())
  )
);

create policy "Approved matching workers can create offers"
on public.offers for insert
to authenticated
with check (
  (select auth.uid()) = worker_id
  and exists (
    select 1
    from public.service_requests sr
    join public.categories c on c.id = sr.category_id
    join public.profiles p on p.id = (select auth.uid())
    join public.worker_profiles wp on wp.user_id = p.id
    where sr.id = offers.request_id
      and sr.status in ('new', 'offered')
      and p.role = 'worker'
      and p.status = 'active'
      and wp.approval_status = 'approved'
      and wp.profession = c.name
      and p.area = sr.area
  )
);

create or replace function public.mark_request_as_offered()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  update public.service_requests
  set status = 'offered',
      updated_at = now()
  where id = new.request_id
    and status = 'new';

  return new;
end;
$$;

drop trigger if exists on_offer_created on public.offers;

create trigger on_offer_created
  after insert on public.offers
  for each row execute procedure public.mark_request_as_offered();
