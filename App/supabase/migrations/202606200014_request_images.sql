insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'request-images',
  'request-images',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create table if not exists public.request_images (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.service_requests(id) on delete cascade,
  storage_path text not null unique,
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now()
);

create index if not exists request_images_request_id_idx
on public.request_images (request_id, sort_order);

alter table public.request_images enable row level security;

revoke all on table public.request_images from anon, authenticated;
grant select, insert on table public.request_images to authenticated;

create policy "Customers can add images to own requests"
on public.request_images for insert
to authenticated
with check (
  exists (
    select 1
    from public.service_requests sr
    where sr.id = request_id
      and sr.customer_id = (select auth.uid())
  )
);

create policy "Customers can read own request images"
on public.request_images for select
to authenticated
using (
  exists (
    select 1
    from public.service_requests sr
    where sr.id = request_id
      and sr.customer_id = (select auth.uid())
  )
);

create policy "Workers can read matching request images"
on public.request_images for select
to authenticated
using (
  exists (
    select 1
    from public.service_requests sr
    join public.profiles p on p.id = (select auth.uid())
    join public.worker_profiles wp on wp.user_id = p.id
    join public.categories c on c.id = sr.category_id
    where sr.id = request_id
      and sr.status in ('new', 'offered')
      and p.role = 'worker'
      and p.status = 'active'
      and wp.approval_status = 'approved'
      and wp.profession = c.name
      and (
        (
          p.area_id is not null
          and sr.area_id is not null
          and p.area_id = sr.area_id
        )
        or p.area = sr.area
      )
  )
);

create policy "Accepted workers can read request images"
on public.request_images for select
to authenticated
using (
  exists (
    select 1
    from public.service_requests sr
    join public.offers o on o.request_id = sr.id
    where sr.id = request_id
      and o.worker_id = (select auth.uid())
      and o.status = 'accepted'
  )
);

create policy "Customers upload request images"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'request-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1
    from public.service_requests sr
    where sr.id = ((storage.foldername(name))[2])::uuid
      and sr.customer_id = (select auth.uid())
  )
);

create policy "Authenticated users read allowed request images"
on storage.objects for select
to authenticated
using (
  bucket_id = 'request-images'
  and exists (
    select 1
    from public.request_images ri
    where ri.storage_path = name
      and (
        exists (
          select 1
          from public.service_requests sr
          where sr.id = ri.request_id
            and sr.customer_id = (select auth.uid())
        )
        or exists (
          select 1
          from public.service_requests sr
          join public.profiles p on p.id = (select auth.uid())
          join public.worker_profiles wp on wp.user_id = p.id
          join public.categories c on c.id = sr.category_id
          where sr.id = ri.request_id
            and sr.status in ('new', 'offered')
            and p.role = 'worker'
            and p.status = 'active'
            and wp.approval_status = 'approved'
            and wp.profession = c.name
            and (
              (
                p.area_id is not null
                and sr.area_id is not null
                and p.area_id = sr.area_id
              )
              or p.area = sr.area
            )
        )
        or exists (
          select 1
          from public.service_requests sr
          join public.offers o on o.request_id = sr.id
          where sr.id = ri.request_id
            and o.worker_id = (select auth.uid())
            and o.status = 'accepted'
        )
      )
  )
);
