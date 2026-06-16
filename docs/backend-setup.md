# إعداد Backend الفعلي

التطبيق يستخدم Supabase Free للتسجيل وقاعدة البيانات.

## إنشاء المشروع

1. أنشئ مشروعًا جديدًا من لوحة Supabase.
2. افتح `SQL Editor`.
3. نفذ محتوى الملف:
   `supabase/migrations/202606150001_create_accounts.sql`
4. من `Project Settings > API` انسخ:
   - Project URL
   - Publishable key

## ملف الإعداد

انسخ `config/backend.example.json` باسم `config/backend.json` ثم ضع القيم الحقيقية.

## تشغيل التطبيق

```powershell
flutter run --dart-define-from-file=config/backend.json
```

لا تضع `service_role` داخل تطبيق الهاتف.

## التسجيل

- العميل يصبح `active` بعد إنشاء الحساب.
- الصنايعي يصبح `pending`.
- بيانات الحساب تنشأ تلقائيًا بواسطة Database Trigger.
- إذا كان تأكيد البريد مفعّلًا، يفتح المستخدم رسالة التأكيد ثم يسجل الدخول.

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
