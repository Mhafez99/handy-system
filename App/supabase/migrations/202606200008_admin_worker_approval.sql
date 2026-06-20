create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;

revoke all on table public.admin_users from anon, authenticated;
grant select on table public.admin_users to authenticated;

create policy "Admins can read their own admin marker"
on public.admin_users for select
to authenticated
using ((select auth.uid()) = user_id);

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.admin_users
    where user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

create or replace function public.admin_list_pending_workers()
returns table (
  user_id uuid,
  full_name text,
  phone text,
  governorate text,
  area text,
  address text,
  profession text,
  years_experience smallint,
  bio text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  return query
  select
    p.id as user_id,
    p.full_name,
    p.phone,
    p.governorate,
    p.area,
    p.address,
    wp.profession,
    wp.years_experience,
    wp.bio,
    p.created_at
  from public.profiles p
  join public.worker_profiles wp on wp.user_id = p.id
  where p.role = 'worker'
    and p.status = 'pending'
    and wp.approval_status = 'pending'
  order by p.created_at asc;
end;
$$;

create or replace function public.admin_approve_worker(p_worker_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  update public.profiles
  set status = 'active',
      updated_at = now()
  where id = p_worker_id
    and role = 'worker';

  update public.worker_profiles
  set approval_status = 'approved',
      reviewed_at = now()
  where user_id = p_worker_id;

  if not found then
    raise exception 'Worker was not found';
  end if;
end;
$$;

create or replace function public.admin_reject_worker(p_worker_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  update public.profiles
  set status = 'suspended',
      updated_at = now()
  where id = p_worker_id
    and role = 'worker';

  update public.worker_profiles
  set approval_status = 'rejected',
      reviewed_at = now()
  where user_id = p_worker_id;

  if not found then
    raise exception 'Worker was not found';
  end if;
end;
$$;

revoke all on function public.admin_list_pending_workers() from public;
revoke all on function public.admin_approve_worker(uuid) from public;
revoke all on function public.admin_reject_worker(uuid) from public;

grant execute on function public.admin_list_pending_workers() to authenticated;
grant execute on function public.admin_approve_worker(uuid) to authenticated;
grant execute on function public.admin_reject_worker(uuid) to authenticated;
