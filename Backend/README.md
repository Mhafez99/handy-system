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
