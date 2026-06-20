create or replace function public.complete_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.service_requests
  set status = 'completed',
      updated_at = now()
  where id = p_request_id
    and customer_id = (select auth.uid())
    and status = 'in_progress';

  if not found then
    raise exception 'Request is not available to complete';
  end if;
end;
$$;

revoke all on function public.complete_request(uuid) from public;
grant execute on function public.complete_request(uuid) to authenticated;
