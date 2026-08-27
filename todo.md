# Hajeen AI Flutter TODO

- [x] إصلاح إعادة توجيه Notifications وFiles وAgents إلى Chat
- [x] ضمان حفظ معرّف المستخدم لكل استجابة تسجيل دخول بصيغة مستقرة
- [x] منع استخدام مساحة التخزين anonymous بعد تسجيل الدخول
- [x] تنظيف حالة Cubit وذاكرة المحادثات عند تبديل الحساب
- [x] إضافة اختبارات regression للتنقل وعزل التخزين بين الحسابات
- [x] تشغيل اختبارات Flutter وبناء APK Android للتحقق
- [x] رفع إصلاحات Flutter إلى فرع main في GitHub
- [x] إصلاح خطأ Android: baseUrl يساوي `/api/v1` بدلاً من عنوان HTTPS كامل
- [x] إضافة اختبار يمنع تمرير baseUrl نسبي إلى Dio على Android
- [x] إعادة بناء APK والتحقق من وجود عنوان Backend مطلق داخله

## سجل التشخيص

سبب الشاشة الحمراء هو تمرير API_BASE_URL فارغاً أثناء البناء؛ لأن String.fromEnvironment يستبدل defaultValue بقيمة فارغة، فنتج resolvedApiUrl يساوي `/api/v1`، وهو عنوان نسبي غير صالح على Android.
- [x] تشخيص سبب ظهور No internet connection في تسجيل الدخول والتسجيل رغم اتصال الجهاز
- [x] تصحيح تصنيف أخطاء المصادقة وعدم تحويل كل أخطاء Dio إلى انقطاع اتصال
- [x] التحقق من عنوان Backend ومسارات auth على HTTPS من بيئة البناء
- [x] إضافة اختبارات regression وبناء APK جديد لاختبار Facebook وGoogle وEmail

## طلب المستخدم الجديد

- [x] ربط قسم الاشتراك بمسار اشتراك فعلي بدلاً من إعادة التوجيه إلى Chat
- [x] ربط قسم سجل المدفوعات بمسار فعلي بدلاً من إعادة التوجيه إلى Chat
- [x] إصلاح أخطاء NotFound في Notifications وFiles وAgents
- [x] إضافة زر اختيار ورفع الصور والملفات والفيديو والأنواع المدعومة في المحادثة
- [x] ربط المرفقات برسالة المحادثة وإظهار حالة الرفع والفشل
- [x] استبدال عنوان محادثة جديدة بعنوان مشتق من أول رسالة للمستخدم
- [x] إضافة اختبارات التكامل والواجهات لهذه التغييرات
- [x] بناء APK جديد ورفع التعديلات إلى فروع GitHub الصحيحة
- [x] Add chat attachment selection, upload metadata, and image/file/video rendering
- [x] Generate meaningful conversation titles from the first user message
- [x] Add regression tests for attachment payloads and automatic titles
- [x] Build and validate Hajeen AI Android APK with the feature fixes

## بلاغات اختبار APK بتاريخ 2026-08-27

- [x] تشخيص رسالة No internet connection عند تسجيل الدخول أو إنشاء الحساب بالبريد
- [x] إصلاح ظهور Google Login is not configured in this build في APK
- [x] إصلاح ظهور Facebook Login is not configured in this build في APK
- [x] إضافة اختبارات regression لإعدادات مزودي OAuth وعنوان Backend
- [x] إعادة بناء APK والتحقق من تسجيل الدخول بالبريد وGoogle وFacebook
