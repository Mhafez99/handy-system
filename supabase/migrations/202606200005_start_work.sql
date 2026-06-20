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
    and sr.status = 'accepted'
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

revoke all on function public.start_work(uuid) from public;
grant execute on function public.start_work(uuid) to authenticated;
