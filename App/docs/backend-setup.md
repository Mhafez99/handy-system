# إعداد Backend الفعلي

التطبيق يستخدم Supabase Free للتسجيل وقاعدة البيانات.

## إنشاء المشروع

1. أنشئ مشروعًا جديدًا من لوحة Supabase.
2. افتح `SQL Editor`.
3. نفذ محتوى الملف الأول:
   `supabase/migrations/202606150001_create_accounts.sql`
4. نفذ محتوى الملف الثاني:
   `supabase/migrations/202606200001_create_services_and_requests.sql`
5. نفذ محتوى ملف العروض:
   `supabase/migrations/202606200002_create_offers.sql`
6. نفذ محتوى ملف قبول العروض:
   `supabase/migrations/202606200003_accept_offers.sql`
7. نفذ محتوى ملف طلبات الصنايعي المقبولة:
   `supabase/migrations/202606200004_worker_accepted_requests.sql`
8. نفذ محتوى ملف بدء الشغل:
   `supabase/migrations/202606200005_start_work.sql`
9. نفذ محتوى ملف إتمام الخدمة:
   `supabase/migrations/202606200006_complete_request.sql`
   `supabase/migrations/202606200016_completion_code.sql`
   `supabase/migrations/202606200017_realtime.sql`
   `supabase/migrations/202606200018_complaints.sql`
   `supabase/migrations/202606200019_admin_overview.sql`
   `supabase/migrations/202606200020_admin_overview_filters.sql`
   `supabase/migrations/202606200021_admin_users_services.sql`
   `supabase/migrations/202606200022_performance_indexes.sql`
10. نفذ محتوى ملف التقييمات:
   `supabase/migrations/202606200007_service_reviews.sql`
11. نفذ محتوى ملف لوحة الإدارة:
   `supabase/migrations/202606200008_admin_worker_approval.sql`
12. نفذ محتوى ملف ملخص تقييم الصنايعي:
   `supabase/migrations/202606200009_worker_rating_summary.sql`
13. نفذ محتوى ملف تفاصيل الصنايعي العامة:
   `supabase/migrations/202606200010_worker_public_details.sql`
14. نفذ محتوى ملف المناطق المنظمة:
   `supabase/migrations/202606200011_create_areas.sql`
15. نفذ محتوى ملف إدارة المناطق من لوحة الإدارة:
   `supabase/migrations/202606200012_admin_manage_areas.sql`
16. نفذ محتوى ملف صلاحية تعديل المنطقة في الملف الشخصي:
   `supabase/migrations/202606200013_profile_area_id_update.sql`
17. نفذ محتوى ملف صور الطلبات:
   `supabase/migrations/202606200014_request_images.sql`
18. نفذ محتوى ملف حالة في الطريق:
   `supabase/migrations/202606200015_on_the_way_status.sql`
19. من `Project Settings > API` انسخ:
   - Project URL
   - Publishable key

## ملف الإعداد

انسخ `config/backend.example.json` باسم `config/backend.json` ثم ضع القيم الحقيقية.

## تشغيل التطبيق

```powershell
flutter run --dart-define-from-file=config/backend.json
```

لا تضع `service_role` داخل تطبيق الهاتف.

## التسجيل والطلبات

- العميل يصبح `active` بعد إنشاء الحساب.
- الصنايعي يصبح `pending`.
- بيانات الحساب تنشأ تلقائيًا بواسطة Database Trigger.
- إذا كان تأكيد البريد مفعّلًا، يفتح المستخدم رسالة التأكيد ثم يسجل الدخول.
- الخدمات الأساسية والطلبات تحفظ في جداول `categories` و`services` و`service_requests`.
- الصنايعي المعتمد يرى الطلبات الجديدة التي تطابق تخصصه ومنطقته فقط.
- العروض تحفظ في جدول `offers`، والعميل يرى عروض طلباته فقط، والصنايعي يرى عروضه فقط.
- قبول العرض يتم بدالة `accept_offer` لتحديث الطلب إلى `accepted` ورفض باقي العروض المعلقة.
- بعد قبول العرض، الصنايعي المقبول فقط يرى بيانات العميل وطلبه داخل قسم `طلباتي المقبولة`.
- الصنايعي المقبول فقط يستطيع تحويل الطلب من `accepted` إلى `in_progress` بدالة `start_work`.
- الصنايعي المقبول فقط يستطيع إتمام الطلب من `in_progress` إلى `completed` بدالة `complete_request_by_worker` بكود الإتمام والسعر النهائي.
- العميل يرى كود الإتمام أثناء `in_progress` ولا يؤكد الإتمام بنفسه.
- العميل صاحب الطلب المكتمل فقط يستطيع إرسال تقييم مرة واحدة بدالة `submit_service_review`.
- تقييم الطلب يظهر للعميل داخل التفاصيل، ويظهر للصنايعي داخل طلباته المكتملة.
- ملخص تقييم الصنايعي يظهر للعميل داخل كارت العرض بدالة `worker_rating_summary`.
- صفحة تفاصيل الصنايعي تستخدم دالة `worker_public_details` لعرض النبذة وآخر التقييمات.
- لوحة الإدارة تستخدم دوال `admin_list_pending_workers` و`admin_approve_worker` و`admin_reject_worker`.
- إدارة المناطق من لوحة الإدارة تستخدم دوال `admin_list_areas` و`admin_create_area` و`admin_update_area`.
- مراجعة الشكاوى من لوحة الإدارة تستخدم دوال `admin_list_complaints` و`admin_update_complaint_status`.
- لوحة المتابعة تستخدم دوال `admin_overview_stats` و`admin_list_recent_requests` و`admin_overview_daily_trend`.
- إدارة المستخدمين تستخدم دوال `admin_list_users` و`admin_update_user_status`.
- إدارة الخدمات تستخدم دوال `admin_list_categories` و`admin_create_category` و`admin_update_category` و`admin_list_services` و`admin_create_service` و`admin_update_service`.

## الشكاوى

- العميل يرسل شكوى على الطلب المكتمل من تفاصيل الطلب بدالة `submit_service_complaint`.
- كل طلب يقبل شكوى واحدة فقط، ويتحول إلى حالة `complaint`.
- الشكاوى تحفظ في جدول `service_complaints` مع سبب ووصف وحالة مراجعة.
- تأكد من تنفيذ migration `202606200018_complaints.sql`.

## لوحة المتابعة (Admin)

- تعرض إحصائيات الطلبات والعملاء والصنايعية والعروض والشكاوى.
- تعرض أحدث الطلبات مع حالتها والعميل والصنايعي المقبول.
- تدعم فلترة بالفترة الزمنية (اليوم / 7 أيام / 30 يوم / الكل / مخصص) وفلترة قائمة الطلبات بالحالة.
- تعرض رسمًا يوميًا للطلبات وتوزيعًا بيانيًا للحالات.
- تأكد من تنفيذ migration `202606200019_admin_overview.sql` ثم `202606200020_admin_overview_filters.sql`.

## إدارة المستخدمين والخدمات (Admin)

- تبويب **المستخدمون**: عرض العملاء والصنايعية مع فلترة بالدور والحالة، وإيقاف/تفعيل الحسابات.
- إيقاف الحساب يضبط `profiles.status` إلى `suspended` فيمنع إنشاء الطلبات والعروض.
- تبويب **الخدمات**: إدارة التخصصات (`categories`) والخدمات (`services`) مع إخفاء/تفعيل.
- التخصصات النشطة فقط تظهر في التطبيق عند إنشاء الطلب.
- تأكد من تنفيذ migration `202606200021_admin_users_services.sql`.

## الشروط وسياسة الخصوصية

- النصوص العربية متوفرة داخل التطبيق في `lib/features/legal/`.
- تظهر عند التسجيل (موافقة إلزامية) ومن الملف الشخصي وشاشة اختيار نوع الحساب.
- راجع المحتوى وعدّل بيانات التواصل أو التفاصيل القانونية قبل الإطلاق العام.

## التوسع وتحمّل الضغط

- للخطة الكاملة لإعادة البناء التدريجي راجع `docs/scalability-rebuild-plan.md`.
- نفّذ migration `202606200022_performance_indexes.sql` قبل إطلاق واسع.
- مشروع API: `Backend/` — راجع `Backend/README.md`.

### تشغيل API محليًا

```powershell
cd Backend
copy .env.example .env
# ضع DATABASE_URL من Supabase (يفضّل pooler :6543)
# ضع SUPABASE_JWT_SECRET من Supabase > API > JWT Settings
# لصور الطلب: SUPABASE_URL و SUPABASE_SERVICE_ROLE_KEY (سري — في الـ API فقط)
# اختياري: REDIS_URL لتحديد معدّل الطلبات (redis://localhost:6379 محليًا)
# اختياري: FCM_SERVER_KEY لإرسال الإشعارات — راجع docs/push-notifications-setup.md
dart pub get
dart run bin/server.dart
```

### ربط Flutter بالـ API

أضف `HANDY_API_URL` في `config/backend.json`:

```json
{
  "HANDY_API_URL": "http://10.0.2.2:8080"
}
```

عند وجود القيمة، يحمّل التطبيق التخصصات والخدمات والمناطق وقوائم الطلبات و**إنشاء الطلب** و**تفاصيل الطلب** و**إرسال العرض** و**إلغاء الطلب** و**تقديم الشكوى** و**التقييمات** و**ملف الصنايعي** و**صور الطلب** (presigned URLs) وعمليات قبول العرض وتحديث حالة الطلب من API مع JWT من جلسة Supabase.

## استعادة كلمة المرور

- من شاشة تسجيل الدخول اضغط `نسيت كلمة المرور؟` ثم أدخل البريد الإلكتروني.
- Supabase يرسل رابط إعادة التعيين إلى البريد.
- بعد فتح الرابط، يظهر للمستخدم شاشة `كلمة مرور جديدة` داخل التطبيق إذا كان الرابط يعيد التوجيه للتطبيق.
- تأكد من تفعيل البريد في `Authentication > Providers > Email` داخل Supabase.
- أضف رابط إعادة التوجيه المناسب في `Authentication > URL Configuration` إذا كنت تستخدم deep link للتطبيق.

## صور الطلبات

- يتم حفظ الصور في bucket باسم `request-images` داخل Supabase Storage.
- جدول `request_images` يربط كل صورة بطلب الخدمة.
- العميل يرفع حتى 3 صور عند إنشاء الطلب.
- الصنايعي يرى الصور في شاشة إرسال العرض.
- تأكد من تنفيذ migration `202606200014_request_images.sql` لإنشاء الجدول وسياسات Storage.

## حالة في الطريق

- بعد قبول العرض، الصنايعي يحدّث الطلب إلى `on_the_way` بدالة `mark_on_the_way`.
- بعد ذلك يستطيع تحويل الطلب إلى `in_progress` بدالة `start_work`.
- العميل يرى حالة **في الطريق** داخل تفاصيل الطلب.

## كود الإتمام والسعر النهائي

- عند قبول العرض، يولّد النظام كود إتمام من 6 أرقام ويحفظه في `service_requests.completion_code`.
- أثناء حالة `in_progress` يرى العميل الكود داخل تفاصيل الطلب ويعطيه للصنايعي بعد انتهاء الشغل.
- الصنايعي المقبول فقط يستطيع إتمام الطلب بدالة `complete_request_by_worker` بإدخال الكود والسعر النهائي.
- النظام يسجل `final_price` و`payment_method = cash` ثم يحوّل الطلب إلى `completed`.
- تأكد من تنفيذ migration `202606200016_completion_code.sql`.

## التحديثات الفورية (Realtime)

- جداول `service_requests` و`offers` مضافة إلى publication `supabase_realtime`.
- التطبيق يستمع للتغييرات في الصفحة الرئيسية للعميل والصنايعي وفي تفاصيل الطلب.
- تأكد من تنفيذ migration `202606200017_realtime.sql`.
- فعّل Realtime للجداول من `Database > Replication` داخل Supabase إذا لم تظهر التحديثات.

## إنشاء أول حساب إدارة

1. أنشئ حسابًا عاديًا من التطبيق أو Supabase Auth.
2. انسخ `User UID` الخاص بالحساب من `Authentication > Users`.
3. نفذ:

```sql
insert into public.admin_users (user_id)
values ('ADMIN_USER_ID')
on conflict (user_id) do nothing;
```

بعدها يستطيع هذا الحساب تسجيل الدخول في مشروع `handy-admin`.

## اعتماد الصنايعي مؤقتًا

إلى أن يتم بناء لوحة الإدارة، يمكن اعتماد الصنايعي من `SQL Editor`:

```sql
update public.profiles
set status = 'active', updated_at = now()
where id = 'WORKER_USER_ID';

update public.worker_profiles
set approval_status = 'approved', reviewed_at = now()
where user_id = 'WORKER_USER_ID';
```

## إدارة المناطق

المناطق تُدار من جدول `areas` أو من لوحة الإدارة في تبويب **المناطق**.

لإضافة منطقة جديدة يدويًا:

```sql
insert into public.areas (governorate, name, sort_order)
values ('القاهرة', 'الزمالك', 5);
```

لإخفاء منطقة دون حذفها:

```sql
update public.areas
set is_active = false
where governorate = 'القاهرة' and name = 'الزمالك';
```
