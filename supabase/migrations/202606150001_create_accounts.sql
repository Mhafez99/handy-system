create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('customer', 'worker')),
  full_name text not null check (char_length(trim(full_name)) >= 3),
  phone text not null unique check (phone ~ '^01[0-9]{9}$'),
  governorate text not null check (char_length(trim(governorate)) >= 2),
  area text not null check (char_length(trim(area)) >= 2),
  address text not null check (char_length(trim(address)) >= 5),
  status text not null default 'active'
    check (status in ('active', 'pending', 'suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.worker_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  profession text not null
    check (profession in ('سباك', 'كهربائي', 'نجار', 'نقاش', 'فني تكييف')),
  years_experience smallint not null
    check (years_experience between 0 and 70),
  bio text not null check (char_length(trim(bio)) >= 10),
  approval_status text not null default 'pending'
    check (approval_status in ('pending', 'approved', 'rejected')),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.worker_profiles enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.worker_profiles from anon, authenticated;

grant select on table public.profiles to authenticated;
grant update (full_name, phone, governorate, area, address)
on table public.profiles to authenticated;

grant select on table public.worker_profiles to authenticated;
grant update (profession, years_experience, bio)
on table public.worker_profiles to authenticated;

create policy "Users can read their own profile"
on public.profiles for select
to authenticated
using ((select auth.uid()) = id);

create policy "Users can update their own profile"
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy "Workers can read their own professional profile"
on public.worker_profiles for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Workers can update their own professional profile"
on public.worker_profiles for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  account_role text;
begin
  account_role := new.raw_user_meta_data ->> 'role';

  if account_role not in ('customer', 'worker') then
    raise exception 'Invalid account role';
  end if;

  insert into public.profiles (
    id,
    role,
    full_name,
    phone,
    governorate,
    area,
    address,
    status
  )
  values (
    new.id,
    account_role,
    trim(new.raw_user_meta_data ->> 'full_name'),
    trim(new.raw_user_meta_data ->> 'phone'),
    trim(new.raw_user_meta_data ->> 'governorate'),
    trim(new.raw_user_meta_data ->> 'area'),
    trim(new.raw_user_meta_data ->> 'address'),
    case when account_role = 'worker' then 'pending' else 'active' end
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

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
