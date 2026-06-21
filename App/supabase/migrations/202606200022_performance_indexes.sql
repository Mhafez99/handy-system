-- Performance indexes for high read volume (Phase 0 scalability).
-- Safe to run on existing databases; uses IF NOT EXISTS.

create index if not exists idx_sr_customer_created
  on public.service_requests (customer_id, created_at desc);

create index if not exists idx_sr_status_area_category
  on public.service_requests (status, area, category_id)
  where status in ('new', 'offered');

create index if not exists idx_sr_created_at
  on public.service_requests (created_at desc);

create index if not exists idx_sr_status_created
  on public.service_requests (status, created_at desc);

create index if not exists idx_offers_request_status
  on public.offers (request_id, status);

create index if not exists idx_offers_worker_created
  on public.offers (worker_id, created_at desc);

create index if not exists idx_offers_request_worker
  on public.offers (request_id, worker_id);

create index if not exists idx_profiles_role_status
  on public.profiles (role, status);

create index if not exists idx_profiles_phone
  on public.profiles (phone);

create index if not exists idx_worker_profiles_approval
  on public.worker_profiles (approval_status, user_id);

create index if not exists idx_complaints_status_created
  on public.service_complaints (status, created_at desc);

create index if not exists idx_complaints_request
  on public.service_complaints (request_id);

create index if not exists idx_areas_active_lookup
  on public.areas (governorate, sort_order, name)
  where is_active = true;

create index if not exists idx_services_category_active
  on public.services (category_id, name)
  where is_active = true;

create index if not exists idx_categories_active_sort
  on public.categories (sort_order, name)
  where is_active = true;
