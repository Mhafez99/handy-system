# Handy Admin

لوحة إدارة ويب مبنية بـ Next.js لاعتماد أو رفض حسابات الصنايعية في تطبيق Handy.

## التشغيل

```powershell
cd C:\handy-admin
npm run dev
```

افتح:

```text
http://localhost:3000
```

## إعداد Supabase

أنشئ ملف `.env.local` بالقيم التالية:

```env
NEXT_PUBLIC_SUPABASE_URL=your-project-url
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

لا تستخدم `service_role` في هذا المشروع.

## SQL المطلوب

نفذ في Supabase SQL Editor:

```text
C:\handy-app\supabase\migrations\202606200008_admin_worker_approval.sql
```

## إنشاء أول مدير

1. أنشئ حسابًا عاديًا من التطبيق أو من Supabase Auth.
2. انسخ `User UID`.
3. نفذ:

```sql
insert into public.admin_users (user_id)
values ('ADMIN_USER_ID')
on conflict (user_id) do nothing;
```

بعدها سجل الدخول في لوحة الإدارة بنفس البريد وكلمة المرور.

## الوظائف الحالية

- تسجيل دخول الإدارة.
- عرض الصنايعية المعلّقين.
- اعتماد الصنايعي وتحويل حسابه إلى `active`.
- رفض الصنايعي وتحويل حسابه إلى `suspended`.
