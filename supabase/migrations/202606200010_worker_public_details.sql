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
  where worker_id = p_worker_id;

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

revoke all on function public.worker_public_details(uuid) from public;
grant execute on function public.worker_public_details(uuid) to authenticated;
