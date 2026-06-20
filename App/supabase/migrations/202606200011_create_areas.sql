create table if not exists public.areas (
  id bigint generated always as identity primary key,
  governorate text not null check (char_length(trim(governorate)) >= 2),
  name text not null check (char_length(trim(name)) >= 2),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (governorate, name)
);

alter table public.areas enable row level security;

revoke all on table public.areas from anon, authenticated;
grant select on table public.areas to authenticated;

create policy "Authenticated users can read active areas"
on public.areas for select
to authenticated
using (is_active = true);

alter table public.profiles
  add column if not exists area_id bigint references public.areas(id) on delete restrict;

alter table public.service_requests
  add column if not exists area_id bigint references public.areas(id) on delete restrict;

drop policy if exists "Approved workers can read matching new requests"
on public.service_requests;

create policy "Approved workers can read matching new requests"
on public.service_requests for select
to authenticated
using (
  status in ('new', 'offered')
  and exists (
    select 1
    from public.profiles p
    join public.worker_profiles wp on wp.user_id = p.id
    join public.categories c on c.id = service_requests.category_id
    where p.id = (select auth.uid())
      and p.role = 'worker'
      and p.status = 'active'
      and wp.approval_status = 'approved'
      and wp.profession = c.name
      and (
        (
          p.area_id is not null
          and service_requests.area_id is not null
          and p.area_id = service_requests.area_id
        )
        or p.area = service_requests.area
      )
  )
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  account_role text;
  area_id_value bigint;
begin
  account_role := new.raw_user_meta_data ->> 'role';

  if account_role not in ('customer', 'worker') then
    raise exception 'Invalid account role';
  end if;

  area_id_value := nullif(new.raw_user_meta_data ->> 'area_id', '')::bigint;

  insert into public.profiles (
    id,
    role,
    full_name,
    phone,
    governorate,
    area,
    address,
    status,
    area_id
  )
  values (
    new.id,
    account_role,
    trim(new.raw_user_meta_data ->> 'full_name'),
    trim(new.raw_user_meta_data ->> 'phone'),
    trim(new.raw_user_meta_data ->> 'governorate'),
    trim(new.raw_user_meta_data ->> 'area'),
    trim(new.raw_user_meta_data ->> 'address'),
    case when account_role = 'worker' then 'pending' else 'active' end,
    area_id_value
  );

  if account_role = 'worker' then
    insert into public.worker_profiles (
      user_id,
      profession,
      years_experience,
      bio
    )
    values (
      new.id,
      trim(new.raw_user_meta_data ->> 'profession'),
      (new.raw_user_meta_data ->> 'years_experience')::smallint,
      trim(new.raw_user_meta_data ->> 'bio')
    );
  end if;

  return new;
end;
$$;

insert into public.areas (governorate, name, sort_order)
values
  ('القاهرة', 'مدينة نصر', 1),
  ('القاهرة', 'المعادي', 2),
  ('القاهرة', 'مصر الجديدة', 3),
  ('القاهرة', 'التجمع الخامس', 4),
  ('الجيزة', 'الدقي', 1),
  ('الجيزة', 'المهندسين', 2),
  ('الجيزة', 'فيصل', 3)
on conflict (governorate, name) do update
set sort_order = excluded.sort_order,
    is_active = true;
