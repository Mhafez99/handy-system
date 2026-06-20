create or replace function public.accept_offer(p_offer_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_request_id uuid;
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

  update public.offers
  set status = case when id = p_offer_id then 'accepted' else 'rejected' end,
      updated_at = now()
  where request_id = selected_request_id
    and status = 'pending';

  update public.service_requests
  set status = 'accepted',
      updated_at = now()
  where id = selected_request_id;
end;
$$;

revoke all on function public.accept_offer(uuid) from public;
grant execute on function public.accept_offer(uuid) to authenticated;
