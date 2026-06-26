# خطة تطوير Handy — Roadmap

> آخر تحديث: يونيو 2026  
> استخدم `- [ ]` / `- [x]` لتتبع التقدم.

---

## ملخص الجاهزية

| السيناريو | الجاهزية الحالية |
|-----------|------------------|
| 5,000 مسجّل (معظمُهم غير نشطين) | 🟢 ممكن |
| 5,000 DAU (نشطين يوميًا) | 🟢 ممكن | مع Redis + نشر إنتاجي |
| 5,000 متصلين في نفس اللحظة | 🟡 ممكن | يحتاج 8–10 API instances + Supabase Pro + Redis |

| المقياس | حد تقريبي (بعد إعداد الإنتاج) |
|---------|-------------------------------|
| مستخدمون نشطون متزامنون (3 instances) | 1,500–2,000 |
| مستخدمون نشطون متزامنون (8–10 instances) | **5,000+** |
| طلبات جديدة / يوم | 5,000–10,000 |

---

## الجدول الزمني

```
أسبوع 1–2   ████████░░░░░░░░  المرحلة A — إنتاج
أسبوع 3–4   ░░░░████████░░░░  المرحلة B — اختبارات
أسبوع 5–7   ░░░░░░░░████████  المرحلة C — Admin API
أسبوع 8–12  ░░░░░░░░░░░░████  المرحلة D — توسع 5K+
```

---

## المرحلة A — استقرار الإنتاج (أسبوع 1–2)

**الهدف:** تشغيل آمن لـ 500–1,000 مستخدم نشط

- [ ] A1 — ترقية Dart SDK إلى 3.12+ في بيئة التطوير والـ CI
- [ ] A2 — تنفيذ migration الفهارس `202606200022_performance_indexes.sql` على Supabase الإنتاج
- [ ] A3 — ترقية Supabase إلى Pro + تفعيل Session pooler (منفذ 6543)
- [ ] A4 — نشر Backend على خادم (Railway / Fly.io / VPS)
- [ ] A5 — تفعيل Redis (Upstash) + ضبط `REDIS_URL`
- [ ] A6 — إعداد Firebase + `FCM_SERVER_KEY`
- [ ] A7 — Sentry للـ Flutter + Backend
- [ ] A8 — ضبط `HANDY_API_URL` في إنتاج Flutter

**معيار الإنجاز:** API يعمل في الإنتاج، rate limiting مفعّل، إشعارات push تعمل.

---

## المرحلة B — اختبارات وثقة (أسبوع 3–4)

**الهدف:** تغطية كل endpoint + معرفة حدود الأداء

### البنية التحتية للاختبارات

- [ ] B1 — إنشاء `test/helpers/` (server in-process + JWT factory)
- [ ] B5 — CI pipeline: `dart test` على كل PR

### Integration tests (25 endpoint)

#### عام

- [ ] B2a — `GET /health`
- [ ] B2b — `GET /v1/catalog/categories`
- [ ] B2c — `GET /v1/catalog/services`
- [ ] B2d — `GET /v1/catalog/areas`

#### طلبات — عميل

- [ ] B3a — `GET /v1/requests/mine`
- [ ] B3b — `POST /v1/requests` (إنشاء)
- [ ] B3c — `GET /v1/requests/:id` (تفاصيل)
- [ ] B3d — `POST /v1/requests/:id/cancel`
- [ ] B3e — `POST /v1/requests/:id/complaints`
- [ ] B3f — `POST /v1/requests/:id/reviews`
- [ ] B3g — `POST /v1/requests/offers/:offerId/accept`

#### طلبات — صنايعي

- [ ] B3h — `GET /v1/requests/available`
- [ ] B3i — `GET /v1/requests/worker/active`
- [ ] B3j — `GET /v1/requests/worker/completed`
- [ ] B3k — `POST /v1/requests/:id/offers`
- [ ] B3l — `POST /v1/requests/:id/on-the-way`
- [ ] B3m — `POST /v1/requests/:id/start`
- [ ] B3n — `POST /v1/requests/:id/complete`

#### صور الطلب

- [ ] B4a — `GET /v1/requests/:id/images`
- [ ] B4b — `POST /v1/requests/:id/images/upload-urls`

#### صنايعيون وأجهزة

- [ ] B4c — `POST /v1/workers/ratings/summary`
- [ ] B4d — `GET /v1/workers/:workerId`
- [ ] B4e — `PUT /v1/devices/token`
- [ ] B4f — `DELETE /v1/devices/token`

### دورة حياة كاملة

- [ ] B3 — Integration test: create → offer → accept → on-the-way → start → complete → review

### اختبار الحمل

- [ ] B6 — Load test بـ k6: 200 concurrent users
- [ ] B7 — إصلاح الاختناقات المكتشفة (connection pool)

**معيار الإنجاز:** 25/25 endpoint مغطاة، p95 < 500ms عند 200 مستخدم متزامن.

---

## المرحلة C — نقل Admin إلى API (أسبوع 5–7)

**الهدف:** فصل Admin عن DB التشغيلي — لا RPC مباشر

### Backend

- [x] C1 — `admin_middleware` (JWT + فحص `admin_users`)
- [x] C2 — `AdminRepository`

#### endpoints الصنايعية

- [x] C3a — `GET /v1/admin/workers/pending`
- [x] C3b — `POST /v1/admin/workers/:id/approve`
- [x] C3c — `POST /v1/admin/workers/:id/reject`

#### endpoints المناطق

- [x] C3d — `GET /v1/admin/areas`
- [x] C3e — `POST /v1/admin/areas`
- [x] C3f — `PATCH /v1/admin/areas/:id`

#### endpoints الشكاوى

- [x] C3g — `GET /v1/admin/complaints`
- [x] C3h — `PATCH /v1/admin/complaints/:id`

#### endpoints اللوحة

- [x] C4a — `GET /v1/admin/overview/stats`
- [x] C4b — `GET /v1/admin/overview/trend`
- [x] C4c — `GET /v1/admin/requests/recent`

#### endpoints المستخدمين

- [x] C4d — `GET /v1/admin/users`
- [x] C4e — `PATCH /v1/admin/users/:id/status`

#### endpoints الكتالوج

- [x] C4f — `GET /v1/admin/categories`
- [x] C4g — `POST /v1/admin/categories`
- [x] C4h — `PATCH /v1/admin/categories/:id`
- [x] C4i — `GET /v1/admin/services`
- [x] C4j — `POST /v1/admin/services`
- [x] C4k — `PATCH /v1/admin/services/:id`

### Admin (Next.js)

- [x] C5 — تعديل `Admin/src/lib/admin.ts` → HTTP client بدل `supabase.rpc()`
- [x] C6 — Integration tests لـ 18 admin endpoint
- [x] C7 — Cache للإحصائيات (Redis, TTL 60s)

**معيار الإنجاز:** Admin يعمل بالكامل عبر API.

---

## المرحلة D — توسع لـ 5,000+ متزامن

**الهدف:** تحمل **5,000 مستخدم متصل في نفس اللحظة**

> راجع `scale-deployment.md` للتفاصيل الكاملة.

### البنية التحتية

- [x] D1 — Connection pool في Backend (بدل connection واحد)
- [x] D2 — 3 instances API خلف Nginx load balancer (`Backend/deploy/`)
- [x] D3 — Read replica لاستعلامات القراءة (`READ_DATABASE_URL`)
- [x] D4 — Cache للكتالوج (categories / services / areas)
- [ ] D5 — CDN لصور الطلبات (Cloudflare أمام Storage)
- [x] D6 — فهارس مطابقة الصنايعي `202606200024_worker_available_matching.sql`
- [x] D7 — Polling كل 30s على قوائم العميل والصنايعي
- [ ] D8 — Load test: 5000 concurrent (k6) — **مؤجّل**
- [ ] D9 — تنبيهات أداء (Sentry / metrics)

### إعداد إنتاج (مطلوب قبل 5K متزامن)

- [ ] نفّذ migrations الفهارس على Supabase الإنتاج
- [ ] Supabase Pro + Session pooler (6543)
- [ ] Redis إنتاجي (Upstash)
- [ ] 8–10 API instances في الإنتاج
- [ ] `HANDY_API_URL` في Flutter + Admin

**معيار الإنجاز:** 5,000 متزامن بدون `503` أو timeout متكرر.

---

## المرحلة B — اختبارات (مؤجّلة)

> لا حاجة لها الآن — ركّز على النشر والتوسع أولاً.

- [ ] B1–B7 — integration tests + load tests

---

## المرحلة E — تحسينات المنتج (لاحقة)

- [x] E1 — توسيع المناطق والتخصصات
- [ ] E2 — دفع إلكتروني
- [ ] E3 — خرائط وتتبع موقع الصنايعي
- [x] E4 — تقييم الصنايعي من الإدارة
- [ ] E5 — إصدار iOS

---

## ما اكتمل مسبقًا (من خطة التوسع)

راجع `scalability-rebuild-plan.md` للتفاصيل.

- [x] migration فهارس الأداء `202606200022` (في الكود)
- [x] مشروع `Backend/` (Shelf + Dart)
- [x] JWT middleware
- [x] `ApiClient` + `HANDY_API_URL` في Flutter
- [x] Catalog (categories, services, areas)
- [x] طلبات العميل (list, create, details, cancel)
- [x] طلبات الصنايعي (available, active, completed)
- [x] العروض (create, accept) + حالات (on-the-way, start, complete)
- [x] الشكاوى + التقييمات
- [x] ملف الصنايعي + ملخص التقييمات
- [x] صور الطلب (presigned upload + signed read URLs)
- [x] FCM Backend (عند `FCM_SERVER_KEY`)
- [x] FCM Flutter (يحتاج `flutterfire configure`)
- [x] اختبارات unit: auth middleware (2)
- [x] اختبارات unit: rate limit (5)

---

## ما زال مباشرًا على Supabase

- [ ] Auth — مقصود (JWT من Supabase Auth)
- [ ] Realtime — مُقلَّص (التفاصيل فقط)
- [x] لوحة Admin — تعمل عبر API عند ضبط `NEXT_PUBLIC_HANDY_API_URL`
- [ ] Catalog بدون `HANDY_API_URL` — fallback على Supabase

---

## مراجع

| الملف | المحتوى |
|-------|---------|
| `product-spec.md` | مواصفات MVP |
| `backend-setup.md` | إعداد Supabase |
| `scalability-rebuild-plan.md` | خطة التوسع التفصيلية |
| `implementation-plan.md` | خطة التنفيذ الأصلية (MVP) |
| `Backend/README.md` | توثيق API endpoints |
| `push-notifications-setup.md` | إعداد Firebase/FCM |
