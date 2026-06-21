# إعداد Firebase / FCM في التطبيق

## الطريقة 1 — FlutterFire CLI (موصى بها)

### المتطلبات
- حساب Google
- مشروع Firebase مع تطبيق Android (`com.handyapp.handy_app`)

### الأوامر

```powershell
cd App
dart pub global activate flutterfire_cli
dart pub global run flutterfire_cli:flutterfire configure `
  --project=YOUR_FIREBASE_PROJECT_ID `
  --platforms=android `
  --android-package-name=com.handyapp.handy_app `
  --yes
```

ينشئ:
- `lib/firebase_options.dart` (يمكن أن يستبدل النسخة الحالية)
- `android/app/google-services.json`

> إذا لم يكن `flutterfire` في PATH استخدم `dart pub global run flutterfire_cli:flutterfire`.

أو شغّل السكربت:

```powershell
.\scripts\configure-firebase.ps1 -ProjectId YOUR_FIREBASE_PROJECT_ID
```

## الطريقة 2 — يدويًا عبر `config/backend.json`

أضف مفاتيح Firebase إلى `config/backend.json` (انظر `config/backend.example.json`):

```json
{
  "FIREBASE_API_KEY": "...",
  "FIREBASE_APP_ID": "1:...:android:...",
  "FIREBASE_MESSAGING_SENDER_ID": "...",
  "FIREBASE_PROJECT_ID": "...",
  "FIREBASE_STORAGE_BUCKET": "...appspot.com"
}
```

انسخ القيم من **Firebase Console > Project settings > Your apps > Android**.

## التشغيل

```powershell
flutter run --dart-define-from-file=config/backend.json
```

## ماذا يحدث في التطبيق

1. بعد تسجيل الدخول يُطلب إذن الإشعارات (Android 13+)
2. يُسجَّل FCM token في API: `PUT /v1/devices/token`
3. عند وصول إشعار والتطبيق مفتوح → تحديث القوائم تلقائيًا
4. عند الخروج → `DELETE /v1/devices/token`

## السيرفر

أضف في `Backend/.env`:

```env
FCM_SERVER_KEY=your-fcm-legacy-server-key
```

من **Firebase Console > Project settings > Cloud Messaging > Server key**.

## استكشاف الأخطاء

| المشكلة | الحل |
|---------|------|
| لا تصل إشعارات | تأكد من `FCM_SERVER_KEY` + migration `023` + `HANDY_API_URL` |
| التطبيق يبني بدون Firebase | طبيعي بدون `google-services.json` — الإشعارات معطّلة |
| `Firebase initialization failed` | راجع مفاتيح `FIREBASE_*` في `backend.json` |
