# نشر Handy على نطاق واسع (5,000+ متزامن)

> الهدف: تحمل **5,000 مستخدم متصل في نفس اللحظة** — وليس فقط 5,000 مسجّل.

## البنية المستهدفة

```
                    ┌─────────────┐
                    │   Flutter   │
                    │  + Admin    │
                    └──────┬──────┘
                           │ HTTPS
                    ┌──────▼──────┐
                    │   Nginx LB  │  ← deploy/nginx.conf
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
      ┌─────────┐     ┌─────────┐     ┌─────────┐
      │ API x1  │     │ API x2  │     │ API x3  │  ← قابل للزيادة
      └────┬────┘     └────┬────┘     └────┬────┘
           └───────────────┼───────────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
         ┌─────────┐  ┌─────────┐  ┌──────────────┐
         │  Redis  │  │ Postgres│  │ Read Replica │
         │  cache  │  │ primary │  │  (اختياري)   │
         └─────────┘  └─────────┘  └──────────────┘
```

## ما تم تنفيذه في الكود

| التحسين | الفائدة |
|---------|---------|
| Connection pool (25/instance) + prewarm | لا connection واحد للكل الطلبات |
| Read replica (`READ_DATABASE_URL`) | فصل قراءة عن كتابة |
| Catalog cache (Redis, 5 دقائق) | تقليل ضغط على DB للكتالوج |
| Worker available cache (20 ثانية/صنايعي) | أهم مسار للصنايعيين |
| Admin stats cache (60 ثانية) | تخفيف لوحة الإدارة |
| استعلام `/available` محسّن + فهارس | مطابقة أسرع للصنايعي |
| Polling كل 30 ثانية (بدل Realtime على القوائم) | تقليل اتصالات Supabase |
| Docker + Nginx (3 instances) | توسع أفقي |
| `/ready` health check | جاهزية للـ load balancer |

## التشغيل المحلي (3 instances)

```powershell
cd handy-system/Backend
copy .env.example .env
# املأ DATABASE_URL و SUPABASE_JWT_SECRET

cd deploy
docker compose up --build
```

الـ API يكون على: `http://localhost:8080` (عبر Nginx)

## إعداد Supabase للإنتاج

1. **ترقية إلى Pro** على الأقل
2. نفّذ كل الـ migrations بما فيها:
   - `202606200022_performance_indexes.sql`
   - `202606200024_worker_available_matching.sql`
3. استخدم **Session pooler** على المنفذ `6543` في `DATABASE_URL`
4. إن وُجد read replica: ضعه في `READ_DATABASE_URL`

## إعداد Flutter / Admin

```json
{
  "HANDY_API_URL": "https://api.your-domain.com"
}
```

```env
NEXT_PUBLIC_HANDY_API_URL=https://api.your-domain.com
```

## تقدير السعة بعد هذا الإعداد

| المكوّن | العدد | السعة التقريبية |
|---------|-------|-----------------|
| API instances | 3 | ~1,500–2,000 متزامن |
| API instances | 6 | ~3,000–4,000 متزامن |
| API instances | 8–10 | **5,000+ متزامن** |
| Redis | 1 (Upstash Pro) | cache + rate limit |
| Supabase Pro + pooler | 1 | حتى ~500 connection من الـ pooler |

> **قاعدة:** كل API instance بـ `DB_POOL_SIZE=25` = 25 connection max.  
> 10 instances × 25 = 250 connections — يجب أن يتحملها Supabase pooler.

## للوصول لـ 5,000 متزامن — checklist

- [ ] Supabase Pro + pooler (6543)
- [ ] Redis إنتاجي (Upstash أو managed Redis)
- [ ] نفّذ migrations الفهارس على الإنتاج
- [ ] `REDIS_URL` مفعّل على كل API instance
- [ ] `HANDY_API_URL` في Flutter و Admin
- [ ] 8–10 API instances خلف Nginx (زِد `api-4` … في docker-compose)
- [ ] `READ_DATABASE_URL` إن وُجد replica
- [ ] CDN لصور الطلبات (Cloudflare أمام Storage) — المرحلة D5
- [ ] مراقبة: latency, error rate, pool wait time

## متى تزيد instances؟

| المؤشر | الإجراء |
|--------|---------|
| p95 latency > 1s | زِد instances أو cache TTL |
| `Timed out waiting for connection` | زِد `DB_POOL_SIZE` أو instances |
| Redis memory عالي | قلّل TTL أو زِد memory |
| Postgres CPU > 70% | read replica + زِد cache |

## ما لم يُنفَّذ بعد (اختياري لاحقًا)

- CDN للصور (D5)
- Load test رسمي بـ k6 (D8)
- Sentry / تنبيهات (D9)
- Auto-scaling (Kubernetes / Fly.io scale)
