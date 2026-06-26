-- E4: إدارة تقييمات الصنايعي من لوحة الإدارة

alter table public.service_reviews
  add column if not exists is_hidden boolean not null default false;

create index if not exists idx_service_reviews_worker_created
  on public.service_reviews (worker_id, created_at desc);

create index if not exists idx_service_reviews_hidden
  on public.service_reviews (is_hidden)
  where is_hidden = true;

create or replace function public.worker_rating_summary(p_worker_ids uuid[])
returns table (
  worker_id uuid,
  average_rating numeric,
  review_count bigint
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  return query
  select
    sr.worker_id,
    round(avg(sr.rating)::numeric, 1) as average_rating,
    count(*)::bigint as review_count
  from public.service_reviews sr
  where sr.worker_id = any(p_worker_ids)
    and sr.is_hidden = false
  group by sr.worker_id;
end;
$$;

create or replace function public.worker_public_details(p_worker_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  worker_payload jsonb;
  reviews_payload jsonb;
  average_rating numeric;
  review_count bigint;
begin
  select jsonb_build_object(
    'worker_id', p.id,
    'full_name', p.full_name,
    'governorate', p.governorate,
    'area', p.area,
    'profession', wp.profession,
    'years_experience', wp.years_experience,
    'bio', wp.bio,
    'created_at', p.created_at
  )
  into worker_payload
  from public.profiles p
  join public.worker_profiles wp on wp.user_id = p.id
  where p.id = p_worker_id
    and p.role = 'worker'
    and p.status = 'active'
    and wp.approval_status = 'approved';

  if worker_payload is null then
    raise exception 'Worker was not found';
  end if;

  select
    round(avg(rating)::numeric, 1),
    count(*)::bigint
  into average_rating, review_count
  from public.service_reviews
  where worker_id = p_worker_id
    and is_hidden = false;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'rating', rating,
        'comment', comment,
        'created_at', created_at
      )
      order by created_at desc
    ),
    '[]'::jsonb
  )
  into reviews_payload
  from (
    select id, rating, comment, created_at
    from public.service_reviews
    where worker_id = p_worker_id
      and is_hidden = false
    order by created_at desc
    limit 5
  ) latest_reviews;

  return worker_payload
    || jsonb_build_object(
      'average_rating', average_rating,
      'review_count', coalesce(review_count, 0),
      'reviews', reviews_payload
    );
end;
$$;

create or replace function public.admin_list_reviews(
  p_worker_id uuid default null,
  p_min_rating smallint default null,
  p_max_rating smallint default null,
  p_include_hidden boolean default true,
  p_limit integer default 50
)
returns table (
  id uuid,
  request_id uuid,
  worker_id uuid,
  worker_name text,
  worker_phone text,
  customer_id uuid,
  customer_name text,
  customer_phone text,
  rating smallint,
  comment text,
  is_hidden boolean,
  created_at timestamptz,
  service_name text,
  area text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  bounded_limit integer;
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  bounded_limit := least(greatest(coalesce(p_limit, 50), 1), 200);

  return query
  select
    sr.id,
    sr.request_id,
    sr.worker_id,
    worker.full_name as worker_name,
    worker.phone as worker_phone,
    sr.customer_id,
    customer.full_name as customer_name,
    customer.phone as customer_phone,
    sr.rating,
    sr.comment,
    sr.is_hidden,
    sr.created_at,
    service.name as service_name,
    req.area
  from public.service_reviews sr
  join public.profiles worker on worker.id = sr.worker_id
  join public.profiles customer on customer.id = sr.customer_id
  join public.service_requests req on req.id = sr.request_id
  join public.services service on service.id = req.service_id
  where (p_worker_id is null or sr.worker_id = p_worker_id)
    and (p_min_rating is null or sr.rating >= p_min_rating)
    and (p_max_rating is null or sr.rating <= p_max_rating)
    and (p_include_hidden or sr.is_hidden = false)
  order by sr.created_at desc
  limit bounded_limit;
end;
$$;

create or replace function public.admin_update_review_visibility(
  p_review_id uuid,
  p_is_hidden boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  update public.service_reviews
  set is_hidden = coalesce(p_is_hidden, false)
  where id = p_review_id;

  if not found then
    raise exception 'Review was not found';
  end if;
end;
$$;

revoke all on function public.admin_list_reviews(uuid, smallint, smallint, boolean, integer)
from public;
grant execute on function public.admin_list_reviews(uuid, smallint, smallint, boolean, integer)
to authenticated;

revoke all on function public.admin_update_review_visibility(uuid, boolean)
from public;
grant execute on function public.admin_update_review_visibility(uuid, boolean)
to authenticated;
