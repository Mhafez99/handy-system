alter table public.service_requests
  add column if not exists completion_code text,
  add column if not exists final_price integer,
  add column if not exists payment_method text;

update public.service_requests
set completion_code = lpad((floor(random() * 1000000)::int)::text, 6, '0')
where completion_code is null
  and status in ('accepted', 'on_the_way', 'in_progress');

create or replace function public.accept_offer(p_offer_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_request_id uuid;
  generated_code text;
begin
  select o.request_id
  into selected_request_id
  from public.offers o
  join public.service_requests sr on sr.id = o.request_id
  where o.id = p_offer_id
    and sr.customer_id = (select auth.uid())
    and sr.status in ('new', 'offered')
    and o.status = 'pending'
  for update of o, sr;

  if selected_request_id is null then
    raise exception 'Offer is not available for acceptance';
  end if;

  generated_code := lpad((floor(random() * 1000000)::int)::text, 6, '0');

  update public.offers
  set status = case when id = p_offer_id then 'accepted' else 'rejected' end,
      updated_at = now()
  where request_id = selected_request_id
    and status = 'pending';

  update public.service_requests
  set status = 'accepted',
      completion_code = generated_code,
      updated_at = now()
  where id = selected_request_id;
end;
$$;

create or replace function public.complete_request_by_worker(
  p_request_id uuid,
  p_code text,
  p_final_price integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_final_price is null or p_final_price <= 0 then
    raise exception 'Final price is required';
  end if;

  if p_code is null or length(trim(p_code)) = 0 then
    raise exception 'Completion code is required';
  end if;

  update public.service_requests sr
  set status = 'completed',
      final_price = p_final_price,
      payment_method = 'cash',
      updated_at = now()
  where sr.id = p_request_id
    and sr.status = 'in_progress'
    and sr.completion_code = trim(p_code)
    and exists (
      select 1
      from public.offers o
      where o.request_id = sr.id
        and o.worker_id = (select auth.uid())
        and o.status = 'accepted'
    );

  if not found then
    raise exception 'Request is not available to complete or code is invalid';
  end if;
end;
$$;

create or replace function public.complete_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception 'Completion must be confirmed by the worker with the completion code';
end;
$$;

revoke all on function public.complete_request_by_worker(uuid, text, integer) from public;
grant execute on function public.complete_request_by_worker(uuid, text, integer) to authenticated;
