create policy "Accepted workers can read accepted requests"
on public.service_requests for select
to authenticated
using (
  status in ('accepted', 'in_progress', 'completed')
  and exists (
    select 1
    from public.offers o
    where o.request_id = service_requests.id
      and o.worker_id = (select auth.uid())
      and o.status = 'accepted'
  )
);

create policy "Accepted workers can read customer profiles"
on public.profiles for select
to authenticated
using (
  exists (
    select 1
    from public.service_requests sr
    join public.offers o on o.request_id = sr.id
    where sr.customer_id = profiles.id
      and sr.status in ('accepted', 'in_progress', 'completed')
      and o.worker_id = (select auth.uid())
      and o.status = 'accepted'
  )
);
