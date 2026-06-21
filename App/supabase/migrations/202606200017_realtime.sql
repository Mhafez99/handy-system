do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'service_requests'
  ) then
    alter publication supabase_realtime add table public.service_requests;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'offers'
  ) then
    alter publication supabase_realtime add table public.offers;
  end if;
end $$;
