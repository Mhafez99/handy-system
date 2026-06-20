create table if not exists public.service_reviews (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.service_requests(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  worker_id uuid not null references public.profiles(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  comment text not null default '' check (char_length(trim(comment)) <= 500),
  created_at timestamptz not null default now()
);

alter table public.service_reviews enable row level security;

revoke all on table public.service_reviews from anon, authenticated;
grant select on table public.service_reviews to authenticated;

create policy "Customers can read their own service reviews"
on public.service_reviews for select
to authenticated
using ((select auth.uid()) = customer_id);

create policy "Workers can read their own service reviews"
on public.service_reviews for select
to authenticated
using ((select auth.uid()) = worker_id);

create or replace function public.submit_service_review(
  p_request_id uuid,
  p_rating smallint,
  p_comment text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_worker_id uuid;
begin
  if p_rating < 1 or p_rating > 5 then
    raise exception 'Rating must be between 1 and 5';
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
    raise exception 'Request is not available for review';
  end if;

  insert into public.service_reviews (
    request_id,
    customer_id,
    worker_id,
    rating,
    comment
  )
  values (
    p_request_id,
    (select auth.uid()),
    selected_worker_id,
    p_rating,
    trim(coalesce(p_comment, ''))
  );
end;
$$;

revoke all on function public.submit_service_review(uuid, smallint, text)
from public;
grant execute on function public.submit_service_review(uuid, smallint, text)
to authenticated;
