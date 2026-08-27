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
