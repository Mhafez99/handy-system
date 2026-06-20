alter table public.worker_profiles
  drop constraint if exists worker_profiles_profession_check;

alter table public.worker_profiles
  add constraint worker_profiles_profession_check
  check (profession in ('سباك', 'كهربائي', 'نجار', 'نقاش', 'فني تكييف'));

create table if not exists public.categories (
  id bigint generated always as identity primary key,
  name text not null unique,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.services (
  id bigint generated always as identity primary key,
  category_id bigint not null references public.categories(id) on delete restrict,
  name text not null,
  min_price integer not null check (min_price >= 0),
  max_price integer not null check (max_price >= min_price),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (category_id, name)
);

create table if not exists public.service_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  category_id bigint not null references public.categories(id) on delete restrict,
  service_id bigint not null references public.services(id) on delete restrict,
  description text not null check (char_length(trim(description)) >= 10),
  governorate text not null check (char_length(trim(governorate)) >= 2),
  area text not null check (char_length(trim(area)) >= 2),
  address text not null check (char_length(trim(address)) >= 5),
  preferred_time text not null check (char_length(trim(preferred_time)) >= 3),
  status text not null default 'new'
    check (status in ('new', 'offered', 'accepted', 'in_progress', 'completed', 'cancelled', 'complaint')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.categories enable row level security;
alter table public.services enable row level security;
alter table public.service_requests enable row level security;

revoke all on table public.categories from anon, authenticated;
revoke all on table public.services from anon, authenticated;
revoke all on table public.service_requests from anon, authenticated;

grant select on table public.categories to authenticated;
grant select on table public.services to authenticated;
grant select, insert, update on table public.service_requests to authenticated;

create policy "Authenticated users can read active categories"
on public.categories for select
to authenticated
using (true);

create policy "Authenticated users can read active services"
on public.services for select
to authenticated
using (is_active = true);

create policy "Customers can create their own requests"
on public.service_requests for insert
to authenticated
with check (
  (select auth.uid()) = customer_id
  and exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and role = 'customer'
      and status = 'active'
  )
);

create policy "Customers can read their own requests"
on public.service_requests for select
to authenticated
using ((select auth.uid()) = customer_id);

create policy "Customers can cancel their own new requests"
on public.service_requests for update
to authenticated
using (
  (select auth.uid()) = customer_id
  and status in ('new', 'offered')
)
with check (
  (select auth.uid()) = customer_id
  and status = 'cancelled'
);

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
      and p.area = service_requests.area
  )
);

insert into public.categories (name, sort_order)
values
  ('سباك', 1),
  ('كهربائي', 2),
  ('نجار', 3),
  ('نقاش', 4),
  ('فني تكييف', 5)
on conflict (name) do update
set sort_order = excluded.sort_order;

insert into public.services (category_id, name, min_price, max_price)
select c.id, s.name, s.min_price, s.max_price
from public.categories c
join (
  values
    ('سباك', 'تسليك صرف', 150, 400),
    ('سباك', 'تركيب خلاط', 200, 500),
    ('سباك', 'إصلاح تسريب مياه', 200, 700),
    ('سباك', 'تركيب سخان', 350, 900),
    ('كهربائي', 'تغيير مفتاح كهرباء', 100, 250),
    ('كهربائي', 'تركيب نجفة', 200, 600),
    ('كهربائي', 'إصلاح قاطع كهرباء', 250, 800),
    ('كهربائي', 'تمديد سلك جديد', 300, 1200),
    ('نجار', 'إصلاح باب', 250, 800),
    ('نجار', 'تركيب كالون', 150, 400),
    ('نجار', 'إصلاح مطبخ', 400, 1500),
    ('نقاش', 'دهان غرفة', 1000, 3500),
    ('نقاش', 'معالجة رطوبة', 500, 2000),
    ('فني تكييف', 'صيانة تكييف', 300, 800),
    ('فني تكييف', 'تنظيف تكييف', 250, 600),
    ('فني تكييف', 'تركيب تكييف', 800, 1800)
) as s(category_name, name, min_price, max_price)
on c.name = s.category_name
on conflict (category_id, name) do update
set min_price = excluded.min_price,
    max_price = excluded.max_price,
    is_active = true;
