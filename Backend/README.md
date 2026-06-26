# Handy Backend API

طبقة API لتحمّل الضغط العالي — المرحلة 1 من `App/docs/scalability-rebuild-plan.md`.

## المتطلبات

- Dart SDK 3.12+
- اتصال Postgres من Supabase (يفضّل **Session pooler** على المنفذ `6543`)

## الإعداد

```powershell
cd Backend
copy .env.example .env
# عدّل DATABASE_URL في .env
dart pub get
```

## التشغيل

```powershell
dart run bin/server.dart
```

الخدمة تعمل على `http://localhost:8080` افتراضيًا.

## Endpoints

| Method | Path | الوصف |
|--------|------|--------|
| GET | `/health` | فحص صحة الخدمة |
| GET | `/v1/catalog/categories` | التخصصات النشطة |
| GET | `/v1/catalog/services?category_id=1` | الخدمات (فلتر اختياري) |
| GET | `/v1/catalog/areas` | المناطق النشطة |
| POST | `/v1/requests` | إنشاء طلب (عميل) |
| GET | `/v1/requests/<requestId>` | تفاصيل طلب (عميل) |
| POST | `/v1/requests/<requestId>/offers` | إرسال عرض (صنايعي) |
| POST | `/v1/requests/<requestId>/cancel` | إلغاء طلب (عميل) |
| POST | `/v1/requests/<requestId>/complaints` | تقديم شكوى (عميل) |
| POST | `/v1/requests/<requestId>/reviews` | تقديم تقييم (عميل) |
| GET | `/v1/requests/<requestId>/images` | صور الطلب (روابط قراءة موقّعة) |
| POST | `/v1/requests/<requestId>/images/upload-urls` | روابط رفع موقّعة للصور |
| POST | `/v1/workers/ratings/summary` | ملخص تقييمات صنايعية (دفعة) |
| GET | `/v1/workers/<workerId>` | ملف صنايعي عام مع التقييمات |
| GET | `/v1/requests/mine` | طلبات العميل (يتطلب JWT) |
| GET | `/v1/requests/available` | طلبات متاحة للصنايعي (يتطلب JWT) |
| GET | `/v1/requests/worker/active` | طلبات الصنايعي النشطة |
| GET | `/v1/requests/worker/completed` | طلبات الصنايعي المكتملة |
| POST | `/v1/requests/offers/<offerId>/accept` | قبول عرض (عميل) |
| POST | `/v1/requests/<requestId>/on-the-way` | في الطريق (صنايعي) |
| POST | `/v1/requests/<requestId>/start` | بدء الشغل (صنايعي) |
| POST | `/v1/requests/<requestId>/complete` | إتمام بالكود والسعر (صنايعي) |

## المصادقة

المسارات تحت `/v1/requests/*` و `/v1/workers/*` و `/v1/devices/*` تتطلب رأس:

```http
Authorization: Bearer <supabase_access_token>
```

ضع `SUPABASE_JWT_SECRET` في `.env` من:
`Supabase > Project Settings > API > JWT Secret`

لصور الطلب (presigned URLs) أضف أيضًا:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

> `SERVICE_ROLE_KEY` سري — يبقى في الـ API فقط ولا يُضاف أبدًا في تطبيق Flutter.

## Rate limiting (Redis)

عند ضبط `REDIS_URL` يُفعَّل تحديد المعدّل على المسارات المحمية:

| المسار | الحد |
|--------|------|
| `POST /v1/requests` | 10 / ساعة / عميل |
| `POST /v1/requests/:id/offers` | 30 / ساعة / صنايعي |
| `GET /v1/requests/available` | 60 / دقيقة / صنايعي |

محليًا:

```powershell
docker run --rm -p 6379:6379 redis:7
```

Upstash (إنتاج):

```env
REDIS_URL=rediss://default:YOUR_TOKEN@YOUR_HOST.upstash.io:6379
```

بدون `REDIS_URL` يعمل الـ API بدون rate limiting (مناسب للتطوير).

عند تجاوز الحد: `429 Too Many Requests` مع رأس `Retry-After`.

راجع `App/docs/scale-deployment.md` لنشر 5,000+ متزامن.

## Connection pool + read replica

```env
DB_POOL_SIZE=25
DB_READ_POOL_SIZE=25
READ_DATABASE_URL=postgresql://...pooler...:6543/postgres
DB_PREWARM_POOLS=true
```

## Redis cache

```env
REDIS_URL=redis://localhost:6379
CATALOG_CACHE_TTL_SECONDS=300
WORKER_AVAILABLE_CACHE_TTL_SECONDS=20
ADMIN_STATS_CACHE_TTL_SECONDS=60
```

## نشر متعدد الـ instances

```powershell
cd Backend/deploy
docker compose up --build
```

يفتح Nginx على `http://localhost:8080` ويوزّع على 3 instances.

## Admin API

يتطلب JWT + عضوية في `admin_users`.

| Method | Path | الوصف |
|--------|------|--------|
| GET | `/v1/admin/overview/stats` | إحصائيات اللوحة (`?from=&to=`) |
| GET | `/v1/admin/overview/trend` | اتجاه يومي (`?from=&to=`) |
| GET | `/v1/admin/requests/recent` | آخر الطلبات |
| GET | `/v1/admin/workers/pending` | صنايعية معلّقين |
| POST | `/v1/admin/workers/:id/approve` | اعتماد صنايعي |
| POST | `/v1/admin/workers/:id/reject` | رفض صنايعي |
| GET | `/v1/admin/areas` | قائمة المناطق |
| POST | `/v1/admin/areas` | إضافة منطقة |
| PATCH | `/v1/admin/areas/:id` | تعديل منطقة |
| GET | `/v1/admin/complaints` | الشكاوى |
| PATCH | `/v1/admin/complaints/:id` | تحديث حالة شكوى |
| GET | `/v1/admin/users` | المستخدمون (`?role=&status=`) |
| PATCH | `/v1/admin/users/:id/status` | تحديث حالة مستخدم |
| GET | `/v1/admin/categories` | التخصصات |
| POST | `/v1/admin/categories` | إضافة تخصص |
| PATCH | `/v1/admin/categories/:id` | تعديل تخصص |
| GET | `/v1/admin/services` | الخدمات (`?category_id=`) |
| POST | `/v1/admin/services` | إضافة خدمة |
| PATCH | `/v1/admin/services/:id` | تعديل خدمة |
| GET | `/v1/admin/reviews` | تقييمات الصنايعية (`?worker_id=&min_rating=&include_hidden=`) |
| PATCH | `/v1/admin/reviews/:id` | إخفاء/إظهار تقييم (`is_hidden`) |

## Connection pool

```env
DB_POOL_SIZE=10
ADMIN_STATS_CACHE_TTL_SECONDS=60
```

عند ضبط `REDIS_URL` يُخزَّن cache لـ:
- `GET /v1/admin/overview/stats`
- `GET /v1/admin/overview/trend`

TTL افتراضي 60 ثانية، ويُبطَل تلقائيًا بعد أي عملية كتابة admin.

## Push notifications (FCM)

| Method | Path | الوصف |
|--------|------|--------|
| PUT | `/v1/devices/token` | تسجيل توكن الجهاز |
| DELETE | `/v1/devices/token` | إلغاء توكن الجهاز |

```env
FCM_SERVER_KEY=your-fcm-legacy-server-key
```

يُرسل إشعار تلقائيًا بعد: عرض جديد، قبول عرض، تغيير حالة الطلب.

راجع `App/docs/push-notifications-setup.md` لإعداد Firebase في التطبيق.

## ربط لوحة Admin

أضف في `Admin/.env.local`:

```env
NEXT_PUBLIC_HANDY_API_URL=http://localhost:8080
```

عند وجود `NEXT_PUBLIC_HANDY_API_URL` تستخدم اللوحة Admin API بدل Supabase RPC.

## ربط تطبيق Flutter

أضف في `App/config/backend.json`:

```json
{
  "SUPABASE_URL": "...",
  "SUPABASE_PUBLISHABLE_KEY": "...",
  "HANDY_API_URL": "http://10.0.2.2:8080"
}
```

> على محاكي Android استخدم `10.0.2.2` بدل `localhost`.

شغّل التطبيق:

```powershell
flutter run --dart-define-from-file=config/backend.json
```

عند وجود `HANDY_API_URL` يحمّل التطبيق التخصصات والخدمات والمناطق من API بدل Supabase المباشر.

## الخطوة التالية

- [ ] إعداد Firebase محليًا (`scripts/configure-firebase.ps1`)
- [ ] نشر API إنتاجي + Redis + FCM

راجع `App/docs/scalability-rebuild-plan.md` للخطة الكاملة.
