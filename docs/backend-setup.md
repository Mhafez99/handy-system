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
10. نفذ محتوى ملف التقييمات:
   `supabase/migrations/202606200007_service_reviews.sql`
11. نفذ محتوى ملف لوحة الإدارة:
   `supabase/migrations/202606200008_admin_worker_approval.sql`
12. نفذ محتوى ملف ملخص تقييم الصنايعي:
   `supabase/migrations/202606200009_worker_rating_summary.sql`
13. نفذ محتوى ملف تفاصيل الصنايعي العامة:
   `supabase/migrations/202606200010_worker_public_details.sql`
14. من `Project Settings > API` انسخ:
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
- العميل صاحب الطلب فقط يستطيع تحويل الطلب من `in_progress` إلى `completed` بدالة `complete_request`.
- العميل صاحب الطلب المكتمل فقط يستطيع إرسال تقييم مرة واحدة بدالة `submit_service_review`.
- تقييم الطلب يظهر للعميل داخل التفاصيل، ويظهر للصنايعي داخل طلباته المكتملة.
- ملخص تقييم الصنايعي يظهر للعميل داخل كارت العرض بدالة `worker_rating_summary`.
- صفحة تفاصيل الصنايعي تستخدم دالة `worker_public_details` لعرض النبذة وآخر التقييمات.
- لوحة الإدارة تستخدم دوال `admin_list_pending_workers` و`admin_approve_worker` و`admin_reject_worker`.

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
