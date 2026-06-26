-- E1: توسيع المناطق والتخصصات + ربط مهنة الصنايعي بجدول categories

alter table public.worker_profiles
  drop constraint if exists worker_profiles_profession_check;

create or replace function public.validate_worker_profession()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.categories
    where name = new.profession
      and is_active = true
  ) then
    raise exception 'Invalid profession';
  end if;

  return new;
end;
$$;

drop trigger if exists validate_worker_profession_trigger on public.worker_profiles;

create trigger validate_worker_profession_trigger
before insert or update of profession on public.worker_profiles
for each row execute function public.validate_worker_profession();

insert into public.categories (name, sort_order, is_active)
values
  ('حداد', 6, true),
  ('فني أجهزة منزلية', 7, true),
  ('تنظيف منازل', 8, true),
  ('مكافحة حشرات', 9, true)
on conflict (name) do update
set sort_order = excluded.sort_order,
    is_active = true;

insert into public.services (category_id, name, min_price, max_price)
select c.id, s.name, s.min_price, s.max_price
from public.categories c
join (
  values
    ('حداد', 'تركيب باب حديد', 400, 1200),
    ('حداد', 'إصلاح شباك', 200, 600),
    ('حداد', 'تركيب درابزين', 500, 1500),
    ('فني أجهزة منزلية', 'صيانة غسالة', 250, 700),
    ('فني أجهزة منزلية', 'صيانة ثلاجة', 300, 900),
    ('فني أجهزة منزلية', 'صيانة بوتاجاز', 200, 600),
    ('تنظيف منازل', 'تنظيف شقة', 300, 900),
    ('تنظيف منازل', 'تنظيف بعد التشطيب', 500, 1500),
    ('تنظيف منازل', 'تنظيف كنب وسجاد', 200, 600),
    ('مكافحة حشرات', 'مكافحة صراصير', 300, 800),
    ('مكافحة حشرات', 'مكافحة نمل', 250, 700),
    ('مكافحة حشرات', 'رش مبيدات عام', 350, 1000)
) as s(category_name, name, min_price, max_price)
on c.name = s.category_name
on conflict (category_id, name) do update
set min_price = excluded.min_price,
    max_price = excluded.max_price,
    is_active = true;

insert into public.areas (governorate, name, sort_order, is_active)
values
  ('القاهرة', 'حلوان', 5, true),
  ('القاهرة', 'المطرية', 6, true),
  ('القاهرة', 'عين شمس', 7, true),
  ('القاهرة', 'الشروق', 8, true),
  ('القاهرة', 'العباسية', 9, true),
  ('القاهرة', 'المقطم', 10, true),
  ('القاهرة', 'الزمالك', 11, true),
  ('القاهرة', 'وسط البلد', 12, true),
  ('القاهرة', 'الرحاب', 13, true),
  ('القاهرة', 'مدينتي', 14, true),
  ('القاهرة', 'زهراء مدينة نصر', 15, true),
  ('القاهرة', 'القاهرة الجديدة', 16, true),
  ('القاهرة', 'باب الشعرية', 17, true),
  ('القاهرة', 'مدينة بدر', 18, true),
  ('الجيزة', '6 أكتوبر', 4, true),
  ('الجيزة', 'حدائق الأهرام', 5, true),
  ('الجيزة', 'العجوزة', 6, true),
  ('الجيزة', 'الهرم', 7, true),
  ('الجيزة', 'إمبابة', 8, true),
  ('الجيزة', 'بولاق الدكرور', 9, true),
  ('الجيزة', 'الشيخ زايد', 10, true),
  ('الجيزة', 'أكتوبر الجديدة', 11, true),
  ('الإسكندرية', 'سيدي جبير', 1, true),
  ('الإسكندرية', 'سموحة', 2, true),
  ('الإسكندرية', 'المنتزه', 3, true),
  ('الإسكندرية', 'العجمي', 4, true),
  ('الإسكندرية', 'ميامي', 5, true),
  ('الإسكندرية', 'محرم بك', 6, true),
  ('الإسكندرية', 'ستانلي', 7, true),
  ('الإسكندرية', 'العصافرة', 8, true),
  ('القليوبية', 'شبرا الخيمة', 1, true),
  ('القليوبية', 'الخانكة', 2, true),
  ('القليوبية', 'قليوب', 3, true),
  ('القليوبية', 'بنها', 4, true),
  ('القليوبية', 'العبور', 5, true)
on conflict (governorate, name) do update
set sort_order = excluded.sort_order,
    is_active = true;
