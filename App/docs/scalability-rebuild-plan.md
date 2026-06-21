# خطة إعادة البناء لتحمّل الضغط العالي

## الهدف

تحويل Handy من بنية **MVP مباشرة على Supabase** إلى بنية **قابلة للتوسع** تتحمل نموًا حقيقيًا في المستخدمين والطلبات، **دون إعادة كتابة تطبيق Flutter من الصفر**.

## تعريف «الضغط العالي» لهذه الخطة

| المقياس | هدف المرحلة 1 | هدف المرحلة 2 | هدف المرحلة 3 |
|---------|---------------|---------------|---------------|
| مستخدمون مسجّلون | 10K–50K | 50K–500K | 500K+ |
| نشطون يوميًا (DAU) | 1K–5K | 5K–50K | 50K+ |
| طلبات جديدة / يوم | 100–1K | 1K–10K | 10K+ |
| اتصالات متزامنة | مئات | آلاف | عشرات الآلاف |

> **ملاحظة:** مليون مستخدم **مسجّل** ممكن مع الوقت؛ المشكلة الحقيقية هي **النشاط المتزامن** و**معدل الطلبات**، وليس رقم التسجيل وحده.

---

## حالة التنفيذ (آخر تحديث)

### ما اكتمل ✅

| البند | الحالة |
|-------|--------|
| migration فهارس الأداء `202606200022_performance_indexes.sql` | ✅ في الكود — يُنفَّذ على Supabase |
| مشروع `Backend/` (Shelf + Dart) | ✅ |
| JWT middleware | ✅ |
| `ApiClient` + `HANDY_API_URL` في Flutter | ✅ |
| Catalog (categories, services, areas) | ✅ |
| طلبات العميل (list, create, details, cancel) | ✅ |
| طلبات الصنايعي (available, active, completed) | ✅ |
| العروض (create, accept) + حالات (on-the-way, start, complete) | ✅ |
| الشكاوى + التقييمات | ✅ |
| ملف الصنايعي + ملخص التقييمات | ✅ |
| صور الطلب (presigned upload + signed read URLs) | ✅ |

### ما زال مباشرًا على Supabase ⚠️

| البند | السبب |
|-------|--------|
| **Auth** | مقصود — JWT من Supabase Auth |
| **Realtime** | مُقلَّص — الصفحة الرئيسية بدون Realtime؛ التفاصيل فقط |
| **FCM (Backend)** | ✅ جاهز عند `FCM_SERVER_KEY` |
| **FCM (Flutter)** | ✅ جاهز — يحتاج `flutterfire configure` أو مفاتيح `FIREBASE_*` |
| **لوحة Admin** | ما زالت RPCs مباشرة — المرحلة 5 |
| **Catalog بدون `HANDY_API_URL`** | fallback على Supabase |

### الوضع الفعلي الآن (Hybrid)

```
┌─────────────┐     ┌─────────────┐
│ Flutter App │     │ Admin Next  │
└──────┬──────┘     └──────┬──────┘
       │                   │
       │ HANDY_API_URL     │ Supabase RPC مباشر
       │ + Supabase Auth   │
       ▼                   ▼
┌──────────────┐    ┌─────────────────────┐
│ Handy API    │    │ Supabase            │
│ (instance    │───▶│ • Postgres + pooler │
│  واحد)       │    │ • Storage (صور)     │
└──────────────┘    │ • Realtime          │
       │            │ • Auth              │
       └────────────┴─────────────────────┘
```

---

## هل يتحمل عددًا ضخمًا من الطلبات والمستخدمين؟

**الإجابة المختصرة: لا بعد — لكنه أصبح جاهزًا لنطاق «النمو المبكر»، وليس لنطاق «ضغط عالي».**

| النطاق | جاهزية تقريبية | ملاحظة |
|--------|----------------|--------|
| **200–500 مستخدم نشط متزامن** + **500 طلب/يوم** | 🟡 ممكن *إذا* نُفِّذت المرحلة 0 تشغيليًا (فهارس + Pro + pooler + مراقبة) | هدف المرحلة 0 |
| **1K–5K DAU** + **1K طلب/يوم** | 🟡 جزئي | يحتاج rate limiting + تقليل Realtime (مرحلة 1–2) |
| **5K–50K DAU** + **10K طلب/يوم** | 🔴 غير جاهز | يحتاج Push، CDN، matching index، replicas، عدة instances |
| **500K+ مسجّلين** | 🔴 غير جاهز | البنية الكاملة (مراحل 2–6) |

### لماذا ليس «ضخم» بعد؟

1. **API instance واحد** — لا load balancer ولا توسع أفقي
2. **لا Redis** — لا cache ولا rate limiting
3. **Realtime على جداول كاملة** — يتضاعف مع كل مستخدم نشط
4. **`GET /requests/available`** — نفس JOIN المعقد؛ بدون `request_matching_index` (مرحلة 4)
5. **FCM في التطبيق** — Backend جاهز؛ Flutter يحتاج Firebase setup
6. **Admin يقرأ تجميعات ثقيلة** مباشرة من DB التشغيلي
7. **لا اختبار حمل** ولا Sentry — لا نعرف حدود النظام فعليًا
8. **صور بدون CDN** — presigned URLs موجودة لكن bandwidth ما زال على Storage

### ما الذي تحسّن فعلًا؟

- فصل التطبيق عن Postgres للعمليات الحرجة (عند تفعيل `HANDY_API_URL`)
- فهارس للاستعلامات الساخنة
- رفع صور مباشر للـ Storage (بدون مرور الملف عبر API)
- نقطة مركزية لإضافة cache وrate limit لاحقًا

---

## الوضع الحالي (As-Is) — الأصلي

```
┌─────────────┐     ┌─────────────┐
│ Flutter App │     │ Admin Next  │
└──────┬──────┘     └──────┬──────┘
       │                   │
       │  Supabase Client  │  Supabase RPC
       │  (مباشر)          │  (مباشر)
       └─────────┬─────────┘
                 ▼
       ┌─────────────────────┐
       │ Supabase            │
       │ • Postgres + RLS    │
       │ • Auth              │
       │ • Storage (صور)     │
       │ • Realtime (جداول)  │
       └─────────────────────┘
```

### نقاط القوة (نُبقي عليها)

- تطبيق Flutter feature-first جاهز وظيفيًا
- منطق الأعمال موثّق في RPCs وmigrations
- لوحة إدارة Next.js تعمل
- تدفق الطلب الكامل مُختبر

### نقاط الاختناق

1. **كل جهاز يتصل مباشرة بقاعدة البيانات** — لا طبقة API، لا cache، لا rate limiting مركزي
2. **Realtime على جداول كاملة** (`service_requests`, `offers`) — تكلفة اتصالات وأحداث تتضاعف مع المستخدمين
3. **مطابقة الصنايعي عبر RLS مع JOINs** — بطيئة بدون فهارس كافية وعلى نطاق واسع
4. **فهارس قليلة** — معظم الجداول بدون indexes مخصصة للاستعلامات الساخنة
5. **لوحة المتابعة** — تجميعات ثقيلة (`admin_overview_stats`) على الجداول التشغيلية
6. **رفع الصور مباشرة من التطبيق** — bandwidth وStorage يتحملان كل الضغط
7. **لا مراقبة (observability)** — لا Sentry ولا مقاييس أداء عند الاختناق

---

## الوضع المستهدف (To-Be)

```
┌─────────────┐     ┌─────────────┐
│ Flutter App │     │ Admin Next  │
└──────┬──────┘     └──────┬──────┘
       │ HTTPS + JWT       │ HTTPS (service role / admin API)
       ▼                   ▼
┌──────────────────────────────────────────┐
│           API Gateway / Load Balancer     │
└──────────────────┬───────────────────────┘
                   ▼
┌──────────────────────────────────────────┐
│         Handy API (Backend Service)       │
│  • REST أو gRPC                           │
│  • Auth validation                        │
│  • Rate limiting                          │
│  • Business orchestration                 │
└─────┬────────────┬──────────────┬────────┘
      │            │              │
      ▼            ▼              ▼
┌──────────┐ ┌──────────┐ ┌───────────────┐
│ Postgres │ │  Redis   │ │ Job Queue     │
│ (primary)│ │  cache   │ │ (Bull/SQS/    │
│          │ │          │ │  pg-boss)     │
└────┬─────┘ └──────────┘ └───────┬───────┘
     │                             │
     ▼                             ▼
┌──────────┐              ┌─────────────────┐
│ Replica  │              │ Workers         │
│ (reads)  │              │ • Push FCM      │
└──────────┘              │ • Thumbnails    │
                          │ • Admin reports │
                          └─────────────────┘

┌─────────────┐    ┌─────────────┐
│ CDN         │    │ Supabase    │
│ (صور)       │    │ Auth فقط*   │
└─────────────┘    └─────────────┘
```

\* في المرحلة الانتقالية يمكن الإبقاء على Supabase Auth؛ لاحقًا يمكن نقل Auth أو الإبقاء عليه كمزود هوية فقط.

---

## مبدأ إعادة البناء: **توسّع تدريجي وليس إعادة كتابة**

| الطبقة | القرار |
|--------|--------|
| Flutter UI | **إبقاء** — تعديل طبقة البيانات فقط |
| Domain models | **إبقاء** مع توسيع بسيط |
| Repositories | **استبدال** — من Supabase SDK إلى HTTP API client |
| Postgres schema | **إبقاء** مع فهارس + تحسينات + جداول مساعدة |
| RPCs الحرجة | **نقل تدريجي** إلى Backend API |
| Admin | **توجيه** عبر Admin API بدل RPCs مباشرة |
| Realtime | **تقليل** — Push + polling خفيف + realtime للطلب النشط فقط |

---

## المراحل التفصيلية

### المرحلة 0 — تثبيت الأساس (أسبوع 1)

**الهدف:** تحمل الضغط الحالي القريب دون إعادة بناء كاملة.

#### مهام

- [x] migration فهارس الأداء (`202606200022_performance_indexes.sql`) — في الكود
- [ ] **تنفيذ** migration على Supabase الإنتاج
- [ ] ترقية Supabase إلى **Pro** على الأقل
- [ ] تفعيل **Connection Pooling** (Supavisor) + `DATABASE_URL` على المنفذ `6543`
- [ ] مراقبة: Sentry للتطبيق + Supabase metrics + تنبيهات
- [ ] حدود Realtime: إلغاء الاشتراك عند الخروج من الشاشة (مراجعة كاملة)
- [ ] اختبار حمل (k6 أو Artillery) على: قائمة طلبات، إنشاء طلب، عروض

#### فهارس مقترحة

```sql
-- service_requests
create index concurrently if not exists idx_sr_customer_created
  on public.service_requests (customer_id, created_at desc);
create index concurrently if not exists idx_sr_status_area_category
  on public.service_requests (status, area, category_id)
  where status in ('new', 'offered');
create index concurrently if not exists idx_sr_created_at
  on public.service_requests (created_at desc);

-- offers
create index concurrently if not exists idx_offers_request_status
  on public.offers (request_id, status);
create index concurrently if not exists idx_offers_worker
  on public.offers (worker_id, created_at desc);

-- profiles
create index concurrently if not exists idx_profiles_role_status
  on public.profiles (role, status);

-- complaints
create index concurrently if not exists idx_complaints_status_created
  on public.service_complaints (status, created_at desc);
```

**معيار النجاح:** 500 طلب/يوم و 200 مستخدم نشط متزامن بدون أخطاء timeout.

**المدة:** 3–5 أيام

---

### المرحلة 1 — طبقة API أولى (أسابيع 2–4) — **~90% مكتملة في الكود**

**الهدف:** فصل التطبيق عن Postgres المباشر للعمليات الثقيلة.

#### تقنية مقترحة

| الخيار | مناسب لـ | ملاحظة |
|--------|----------|--------|
| **Shelf (Dart)** ✅ المُنفَّذ | فريق Flutter | ما بُني فعليًا |
| **Dart Frog / Serverpod** | فريق Flutter | بديل |
| **Node.js (Fastify)** | سرعة التطوير | ecosystem واسع |
| **Go (Fiber/Echo)** | أداء عالي | أفضل على المدى الطويل |

#### هيكل المشروع الجديد

```
Backend/
  src/
    routes/
      auth/
      requests/
      offers/
      workers/
      catalog/        # categories, services, areas
    services/
    repositories/     # SQL queries
    middleware/
      auth.ts
      rate_limit.ts
    jobs/
  docker-compose.yml  # api + redis + postgres (dev)
```

#### Endpoints — حالة النقل

| Endpoint | يحل محل | الحالة |
|----------|---------|--------|
| `GET /catalog/categories` | `from('categories')` | ✅ |
| `GET /catalog/services` | `from('services')` | ✅ |
| `GET /catalog/areas` | `from('areas')` | ✅ |
| `GET /requests/mine` | `loadCustomerRequests` | ✅ |
| `GET /requests/available` | worker matching RLS | ✅ |
| `POST /requests` | insert | ✅ |
| `GET /requests/:id` | details + offers | ✅ |
| `POST /requests/:id/offers` | `offers.insert` | ✅ |
| `POST /offers/:id/accept` | `accept_offer` RPC | ✅ |
| `POST /requests/:id/on-the-way` | `mark_on_the_way` | ✅ |
| `POST /requests/:id/start` | `start_work` | ✅ |
| `POST /requests/:id/complete` | `complete_request_by_worker` | ✅ |
| `POST /requests/:id/cancel` | update status | ✅ |
| `POST /requests/:id/complaints` | `submit_service_complaint` | ✅ |
| `POST /requests/:id/reviews` | `submit_service_review` | ✅ |
| `GET/POST /requests/:id/images/*` | Storage + `request_images` | ✅ presigned |
| `GET /workers/:id` | `worker_public_details` | ✅ |
| `POST /workers/ratings/summary` | `worker_rating_summary` | ✅ |
| **Rate limiting (Redis)** | — | ✅ |

#### Auth

- التطبيق يحصل على JWT من Supabase Auth (كما هو)
- API يتحقق من JWT عبر **JWKS** من Supabase
- لا `service_role` في التطبيق أبدًا

#### Rate limiting (Redis)

| Endpoint | حد مقترح |
|----------|----------|
| `POST /requests` | 10 / ساعة / عميل |
| `POST /offers` | 30 / ساعة / صنايعي |
| `GET /requests/available` | 60 / دقيقة / صنايعي |

#### تغيير Flutter

```dart
// قبل
_client.from('service_requests').select(...)

// بعد
_apiClient.get('/requests/mine')
```

- إنشاء `ApiClient` مع interceptors للـ JWT وإعادة المحاولة
- Repositories تستدعي API بدل Supabase (feature flag للتبديل التدريجي)

**معيار النجاح:** 100% من عمليات القراءة/الكتابة الحرجة تمر عبر API؛ Supabase client يُستخدم للـ Auth وRealtime فقط.

**الحالة:** منطق التطبيق مكتمل عند `HANDY_API_URL` — **متبقي:** rate limiting + نشر API إنتاجي + إغلاق المرحلة 0 تشغيليًا.

**المدة:** 2–3 أسابيع (معظمه مُنجَز — أسبوع للتشغيل والاختبار)

---

### المرحلة 2 — Push + تقليل Realtime — **~70% مكتملة**

**الهدف:** إزالة الاعتماد على Realtime كآلية أساسية للتحديث.

#### ما اكتمل ✅

- [x] جدول `device_tokens` + migration `023`
- [x] `PUT/DELETE /v1/devices/token`
- [x] إرسال FCM من API (عرض جديد، قبول، تغيير حالة)
- [x] إلغاء Realtime من الصفحة الرئيسية (عميل + صنايعي)
- [x] تحديث عند العودة للتطبيق + تغيير التبويب
- [x] Realtime في تفاصيل الطلب النشط فقط

#### ما تبقى

- [ ] `firebase_messaging` في Flutter + `flutterfire configure`
- [ ] Queue منفصلة للإشعارات (اختياري — حاليًا fire-and-forget)

#### Firebase Cloud Messaging (FCM)

| حدث | المستلم | إجراء |
|-----|---------|-------|
| عرض جديد | عميل | Push + تحديث عند فتح التطبيق |
| قبول عرض | صنايعي | Push |
| تغيير حالة | الطرف الآخر | Push |
| شكوى جديدة | إدارة (اختياري) | Push/Web |

#### تخزين device tokens

```sql
create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('android', 'ios')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);
```

#### Worker إرسال الإشعارات

```
API (بعد accept_offer) → Queue → Notification Worker → FCM
```

#### Realtime بعد التعديل

| الشاشة | Realtime |
|--------|----------|
| الصفحة الرئيسية | **إلغاء** — استبدال بـ Push + pull on resume |
| تفاصيل طلب نشط | **إبقاء** — فلتر `request_id` فقط |
| سجل الطلبات | **إلغاء** — تحديث عند الدخول فقط |

**معيار النجاح:** 80% انخفاض في اتصالات Realtime.

**المدة:** 1–2 أسبوع

---

### المرحلة 3 — صور + CDN (أسبوع 7) — **جزئي**

**الهدف:** فصل bandwidth الصور عن Supabase Storage.

#### ما اكتمل

- [x] presigned upload URLs من API
- [x] signed read URLs من API
- [x] تسجيل metadata في `request_images`

#### ما تبقى

- [ ] CDN أمام Storage (Cloudflare / Supabase CDN)
- [ ] ضغط الصور من التطبيق قبل الرفع
- [ ] Worker لـ thumbnails (اختياري)

---

### المرحلة 4 — تحسين المطابقة والقراءة (أسابيع 8–9)

**الهدف:** استعلام «طلبات متاحة للصنايعي» سريع على نطاق واسع.

#### المشكلة الحالية

RLS يقيّم JOIN على كل صف في `service_requests` — لا يتوسع جيدًا.

#### الحل: Materialized View أو جدول مطابقة

```sql
create table public.request_matching_index (
  request_id uuid primary key references public.service_requests(id) on delete cascade,
  category_name text not null,
  area text not null,
  governorate text not null,
  status text not null,
  created_at timestamptz not null
);

create index idx_rmi_lookup
  on public.request_matching_index (area, category_name, status, created_at desc);
```

- **Trigger** عند insert/update على `service_requests` يحدّث الجدول
- API يقرأ من `request_matching_index` بدل RLS المعقد

#### Read Replica

- استعلامات القراءة (قوائم، سجل) → replica
- الكتابة → primary فقط

**معيار النجاح:** `GET /requests/available` < 200ms عند p95 مع 10K طلب نشط.

**المدة:** 2 أسابيع

---

### المرحلة 5 — لوحة الإدارة والتقارير (أسبوع 10)

**الهدف:** فصل تحليلات الإدارة عن قاعدة التشغيل.

#### تغييرات Admin

- Admin يتصل بـ **Admin API** (ليس Supabase RPC مباشرة)
- تقارير المتابعة من **جداول مجمّعة ليلية**:

```sql
create table public.admin_daily_stats (
  day date primary key,
  total_requests int,
  completed_requests int,
  new_customers int,
  ...
);
```

- Job ليلي يملأ `admin_daily_stats` من primary
- لوحة المتابعة تقرأ من stats + آخر 50 طلب فقط live

**المدة:** 1 أسبوع

---

### المرحلة 6 — صلابة الإنتاج (أسابيع 11–12)

**الهدف:** جاهزية تشغيل 24/7.

#### البنية

- API: **2+ instances** خلف load balancer
- Redis: managed (Upstash / ElastiCache)
- Postgres: Supabase Team أو **RDS/Neon** مع replicas
- Queue: managed (SQS / Upstash Q / pg-boss على Postgres)

#### Observability

| أداة | الغرض |
|------|--------|
| Sentry | أخطاء التطبيق والـ API |
| Grafana / Datadog | مقاييس API وDB |
| Uptime monitor | تنبيه انقطاع |
| Structured logs | تتبع طلبات بطيئة |

#### اختبار حمل نهائي

- محاكاة 5K مستخدم نشط
- 500 طلب/ساعة ذروة
- قياس p50/p95/p99

#### خطة طوارئ

- تعطيل Realtime بالكامل (feature flag)
- تفعيل وضع «قراءة فقط» للصنايعي عند ضغط DB
- Queue backlog monitoring

**المدة:** 2 أسبوع

---

## جدول زمني ملخّص

| المرحلة | المدة | النتيجة |
|---------|-------|---------|
| 0 — فهارس ومراقبة | أسبوع 1 | تحمل فوري أفضل |
| 1 — API layer | أسابيع 2–4 | فصل التطبيق عن DB |
| 2 — Push | أسابيع 5–6 | تقليل Realtime |
| 3 — CDN صور | أسبوع 7 | bandwidth أقل |
| 4 — مطابقة + replica | أسابيع 8–9 | قوائم سريعة |
| 5 — Admin analytics | أسبوع 10 | تقارير بدون ضغط |
| 6 — Production hardening | أسابيع 11–12 | تشغيل مستقر |

**الإجمالي:** ~3 أشهر لفريق 1–2 مطورين بدوام كامل.

---

## ما يُبنى من الصفر وما يُعاد استخدامه

### يُعاد استخدامه ✅

- تطبيق Flutter (الشاشات والـ widgets)
- نماذج Domain
- migrations الحالية + schema
- منطق RPCs (يُنقل كود SQL إلى repositories في API)
- لوحة Admin (واجهة — تغيير مصدر البيانات فقط)
- Supabase Auth (مرحلة انتقالية)

### يُبنى جديد 🆕

- `Backend/` — خدمة API
- `ApiClient` في Flutter
- Redis + Queue + Workers
- FCM integration
- CDN + presigned uploads
- جداول: `device_tokens`, `request_matching_index`, `admin_daily_stats`
- CI/CD للـ API
- اختبارات حمل

### يُلغى تدريجيًا ❌

- Supabase client المباشر من التطبيق (ما عدا Auth)
- Realtime على الجداول الكاملة
- RPCs من التطبيق (تبقى للـ Admin API أو تُحذف)

---

## تقدير تكلفة تشغيل شهرية (تقريبي)

| المرحلة | البنية | تكلفة تقريبة |
|---------|--------|--------------|
| تجربة | Supabase Pro | $25–50 |
| نمو | Pro + Redis + FCM | $100–300 |
| ضغط عالي | Team DB + 2 API instances + CDN | $500–2000+ |

التكلفة تعتمد على المنطقة وعدد الصور والـ DAU الفعلي.

---

## مخاطر وكيف نتعامل معها

| الخطر | التخفيف |
|-------|---------|
| إعادة كتابة كاملة تؤخر الإطلاق | توسّع تدريجي + feature flags |
| ازدواجية منطق (RPC + API) | نقل endpoint واحد في كل مرة + اختبارات |
| انقطاع أثناء النقل | Shadow mode: API يقرأ ويقارن مع Supabase |
| فريق صغير | المرحلة 0 + 1 أولًا؛ الباقي حسب الأرقام |
| تكلفة Supabase Team | تقييم Neon/RDS عند المرحلة 6 |

---

## خارطة طريق تنفيذية (أول 30 يوم)

### الأسبوع 1
1. تنفيذ migration الفهارس
2. ترقية Supabase + تفعيل pooling
3. إضافة Sentry للتطبيق
4. قياس baseline (زمن قائمة الطلبات، إنشاء طلب)

### الأسبوع 2
1. إنشاء مشروع `Backend/` (Dart Frog أو Go)
2. JWT middleware + health check
3. نقل: catalog (categories, services, areas)

### الأسبوع 3
4. نقل: customer requests (list, create, details)
5. `ApiClient` في Flutter + feature flag

### الأسبوع 4
6. نقل: worker available requests + offers
7. نقل: accept, status transitions
8. اختبار حمل أولي

---

## معايير قرار «ننتقل للمرحلة التالية»

| المرحلة | انتقل عندما |
|---------|-------------|
| 0 → 1 | p95 لقائمة الطلبات > 1s أو أخطاء connection |
| 1 → 2 | Realtime connections > 500 متزامنة |
| 2 → 3 | Storage bandwidth > 80% من الحد |
| 4 → 5 | `available requests` > 500ms p95 |
| 5 → 6 | DAU > 5K أو طلبات > 1K/يوم |

---

## الخلاصة

- **لا تحتاج** رمي التطبيق والبدء من صفر.
- **تحتاج** إضافة **طبقة API** + **cache** + **Push** + **فهارس** + **فصل التقارير**.
- ابدأ **المرحلة 0 فور الإطلاق** حتى مع المستخدمين الحاليين.
- نفّذ **المرحلة 1** قبل أن يتجاوز النشاط اليومي بضع مئات الطلبات.
- راقب الأرقام الحقيقية؛ لا تبني لمليون مستخدم قبل أن يظهر الاختناق.

---

## الملفات المرتبطة

- `docs/product-spec.md` — نطاق المنتج
- `docs/implementation-plan.md` — خطة MVP الأصلية
- `docs/backend-setup.md` — إعداد Supabase الحالي
- `supabase/migrations/` — schema الحالي

## الخطوة التالية المقترحة في الكود

### أولوية فورية (إغلاق المرحلة 0 + 1)

1. ~~إنشاء `202606200022_performance_indexes.sql`~~ ✅
2. ~~إنشاء هيكل `Backend/` مع health endpoint~~ ✅
3. ~~إنشاء `App/lib/core/api/api_client.dart`~~ ✅
4. ~~نقل endpoints الطلبات والعروض والصور والتقييمات~~ ✅
5. ~~JWT middleware~~ ✅
6. **تشغيلي:** تنفيذ migration الفهارس على Supabase + Pro + pooler
7. **تشغيلي:** نشر API (Railway / Fly.io / VPS) مع `DATABASE_URL` + `SUPABASE_JWT_SECRET` + Storage keys
8. ~~**كود:** Rate limiting (Redis) على `POST /requests` و`POST /offers` و`GET /available`~~ ✅
9. **اختبار:** k6 baseline — قياس p95 قبل/بعد

### المرحلة 2 — التالية في الكود (أكبر أثر على التوسع)

10. ~~FCM Backend + جدول `device_tokens`~~ ✅
11. ~~تقليل Realtime على الصفحة الرئيسية~~ ✅
12. ~~**Flutter:** FCM + تسجيل التوكن~~ ✅ (يحتاج إعداد Firebase محليًا)
13. **اختبار:** k6 baseline — قياس p95 قبل/بعد

### لاحقًا (حسب الأرقام)

14. `request_matching_index` (مرحلة 4) عند بطء `available`
15. Admin API + `admin_daily_stats` (مرحلة 5)
16. عدة instances API + observability (مرحلة 6)
