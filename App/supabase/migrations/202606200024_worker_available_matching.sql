-- Optimizes worker available-requests matching at scale.
create index if not exists idx_sr_available_worker_match
  on public.service_requests (status, area_id, category_id, created_at desc)
  where status in ('new', 'offered');

create index if not exists idx_profiles_worker_area_match
  on public.profiles (area_id, area, id)
  where role = 'worker' and status = 'active';

create index if not exists idx_worker_profiles_profession_approved
  on public.worker_profiles (profession, user_id)
  where approval_status = 'approved';
