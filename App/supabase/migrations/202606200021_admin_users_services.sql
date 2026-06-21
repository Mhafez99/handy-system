alter table public.categories
  add column if not exists is_active boolean not null default true;

drop policy if exists "Authenticated users can read active categories" on public.categories;

create policy "Authenticated users can read active categories"
on public.categories for select
to authenticated
using (is_active = true);

create or replace function public.admin_list_users(
  p_role text default null,
  p_status text default null
)
returns table (
  user_id uuid,
  full_name text,
  phone text,
  role text,
  governorate text,
  area text,
  status text,
  profession text,
  approval_status text,
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

  if p_role is not null and p_role not in ('customer', 'worker') then
    raise exception 'Invalid role filter';
  end if;

  if p_status is not null and p_status not in ('active', 'pending', 'suspended') then
    raise exception 'Invalid status filter';
  end if;

  return query
  select
    p.id as user_id,
    p.full_name,
    p.phone,
    p.role,
    p.governorate,
    p.area,
    p.status,
    coalesce(wp.profession, '') as profession,
    coalesce(wp.approval_status, '') as approval_status,
    p.created_at
  from public.profiles p
  left join public.worker_profiles wp on wp.user_id = p.id
  where not exists (
    select 1
    from public.admin_users au
    where au.user_id = p.id
  )
    and (p_role is null or p.role = p_role)
    and (p_status is null or p.status = p_status)
  order by p.created_at desc;
end;
$$;

create or replace function public.admin_update_user_status(
  p_user_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_role text;
  target_approval text;
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  if p_status not in ('active', 'suspended') then
    raise exception 'Invalid status';
  end if;

  if p_user_id = (select auth.uid()) then
    raise exception 'Cannot change your own status';
  end if;

  if exists (
    select 1
    from public.admin_users
    where user_id = p_user_id
  ) then
    raise exception 'Cannot change admin account status';
  end if;

  select p.role
  into target_role
  from public.profiles p
  where p.id = p_user_id;

  if not found then
    raise exception 'User was not found';
  end if;

  if p_status = 'active' and target_role = 'worker' then
    select wp.approval_status
    into target_approval
    from public.worker_profiles wp
    where wp.user_id = p_user_id;

    if target_approval is distinct from 'approved' then
      raise exception 'Worker must be approved before activation';
    end if;
  end if;

  update public.profiles
  set status = p_status,
      updated_at = now()
  where id = p_user_id;
end;
$$;

create or replace function public.admin_list_categories()
returns table (
  id bigint,
  name text,
  sort_order integer,
  is_active boolean,
  service_count bigint,
  active_service_count bigint,
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
    c.id,
    c.name,
    c.sort_order,
    c.is_active,
    (
      select count(*)
      from public.services s
      where s.category_id = c.id
    ) as service_count,
    (
      select count(*)
      from public.services s
      where s.category_id = c.id
        and s.is_active = true
    ) as active_service_count,
    c.created_at
  from public.categories c
  order by c.sort_order, c.name;
end;
$$;

create or replace function public.admin_create_category(
  p_name text,
  p_sort_order integer default 0
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_category_id bigint;
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  if char_length(trim(p_name)) < 2 then
    raise exception 'Category name is required';
  end if;

  insert into public.categories (name, sort_order, is_active)
  values (trim(p_name), coalesce(p_sort_order, 0), true)
  returning id into new_category_id;

  return new_category_id;
end;
$$;

create or replace function public.admin_update_category(
  p_category_id bigint,
  p_name text,
  p_sort_order integer,
  p_is_active boolean
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

  if char_length(trim(p_name)) < 2 then
    raise exception 'Category name is required';
  end if;

  update public.categories
  set name = trim(p_name),
      sort_order = coalesce(p_sort_order, 0),
      is_active = coalesce(p_is_active, true)
  where id = p_category_id;

  if not found then
    raise exception 'Category was not found';
  end if;
end;
$$;

create or replace function public.admin_list_services(
  p_category_id bigint default null
)
returns table (
  id bigint,
  category_id bigint,
  category_name text,
  name text,
  min_price integer,
  max_price integer,
  is_active boolean,
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
    s.id,
    s.category_id,
    c.name as category_name,
    s.name,
    s.min_price,
    s.max_price,
    s.is_active,
    s.created_at
  from public.services s
  join public.categories c on c.id = s.category_id
  where p_category_id is null or s.category_id = p_category_id
  order by c.sort_order, c.name, s.name;
end;
$$;

create or replace function public.admin_create_service(
  p_category_id bigint,
  p_name text,
  p_min_price integer,
  p_max_price integer
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_service_id bigint;
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  if p_category_id is null then
    raise exception 'Category is required';
  end if;

  if char_length(trim(p_name)) < 2 then
    raise exception 'Service name is required';
  end if;

  if p_min_price is null or p_min_price < 0 then
    raise exception 'Invalid minimum price';
  end if;

  if p_max_price is null or p_max_price < p_min_price then
    raise exception 'Invalid maximum price';
  end if;

  if not exists (
    select 1
    from public.categories c
    where c.id = p_category_id
  ) then
    raise exception 'Category was not found';
  end if;

  insert into public.services (
    category_id,
    name,
    min_price,
    max_price,
    is_active
  )
  values (
    p_category_id,
    trim(p_name),
    p_min_price,
    p_max_price,
    true
  )
  returning id into new_service_id;

  return new_service_id;
end;
$$;

create or replace function public.admin_update_service(
  p_service_id bigint,
  p_category_id bigint,
  p_name text,
  p_min_price integer,
  p_max_price integer,
  p_is_active boolean
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

  if p_category_id is null then
    raise exception 'Category is required';
  end if;

  if char_length(trim(p_name)) < 2 then
    raise exception 'Service name is required';
  end if;

  if p_min_price is null or p_min_price < 0 then
    raise exception 'Invalid minimum price';
  end if;

  if p_max_price is null or p_max_price < p_min_price then
    raise exception 'Invalid maximum price';
  end if;

  update public.services
  set category_id = p_category_id,
      name = trim(p_name),
      min_price = p_min_price,
      max_price = p_max_price,
      is_active = coalesce(p_is_active, true)
  where id = p_service_id;

  if not found then
    raise exception 'Service was not found';
  end if;
end;
$$;

revoke all on function public.admin_list_users(text, text) from public;
revoke all on function public.admin_update_user_status(uuid, text) from public;
revoke all on function public.admin_list_categories() from public;
revoke all on function public.admin_create_category(text, integer) from public;
revoke all on function public.admin_update_category(bigint, text, integer, boolean) from public;
revoke all on function public.admin_list_services(bigint) from public;
revoke all on function public.admin_create_service(bigint, text, integer, integer) from public;
revoke all on function public.admin_update_service(bigint, bigint, text, integer, integer, boolean) from public;

grant execute on function public.admin_list_users(text, text) to authenticated;
grant execute on function public.admin_update_user_status(uuid, text) to authenticated;
grant execute on function public.admin_list_categories() to authenticated;
grant execute on function public.admin_create_category(text, integer) to authenticated;
grant execute on function public.admin_update_category(bigint, text, integer, boolean) to authenticated;
grant execute on function public.admin_list_services(bigint) to authenticated;
grant execute on function public.admin_create_service(bigint, text, integer, integer) to authenticated;
grant execute on function public.admin_update_service(bigint, bigint, text, integer, integer, boolean) to authenticated;
