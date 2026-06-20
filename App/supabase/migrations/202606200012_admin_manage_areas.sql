create or replace function public.admin_list_areas()
returns table (
  id bigint,
  governorate text,
  name text,
  sort_order integer,
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
    a.id,
    a.governorate,
    a.name,
    a.sort_order,
    a.is_active,
    a.created_at
  from public.areas a
  order by a.governorate, a.sort_order, a.name;
end;
$$;

create or replace function public.admin_create_area(
  p_governorate text,
  p_name text,
  p_sort_order integer default 0
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_area_id bigint;
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  if char_length(trim(p_governorate)) < 2 then
    raise exception 'Governorate is required';
  end if;

  if char_length(trim(p_name)) < 2 then
    raise exception 'Area name is required';
  end if;

  insert into public.areas (governorate, name, sort_order, is_active)
  values (trim(p_governorate), trim(p_name), coalesce(p_sort_order, 0), true)
  returning id into new_area_id;

  return new_area_id;
end;
$$;

create or replace function public.admin_update_area(
  p_area_id bigint,
  p_governorate text,
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

  if char_length(trim(p_governorate)) < 2 then
    raise exception 'Governorate is required';
  end if;

  if char_length(trim(p_name)) < 2 then
    raise exception 'Area name is required';
  end if;

  update public.areas
  set governorate = trim(p_governorate),
      name = trim(p_name),
      sort_order = coalesce(p_sort_order, 0),
      is_active = coalesce(p_is_active, true)
  where id = p_area_id;

  if not found then
    raise exception 'Area was not found';
  end if;
end;
$$;

revoke all on function public.admin_list_areas() from public;
revoke all on function public.admin_create_area(text, text, integer) from public;
revoke all on function public.admin_update_area(bigint, text, text, integer, boolean) from public;

grant execute on function public.admin_list_areas() to authenticated;
grant execute on function public.admin_create_area(text, text, integer) to authenticated;
grant execute on function public.admin_update_area(bigint, text, text, integer, boolean) to authenticated;
