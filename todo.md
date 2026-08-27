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

## بلاغات اختبار APK الجديدة

- [x] إصلاح عدم تمرير إعداد Facebook في نسخة Android المستخدمة فعلياً
- [x] منع ظهور محادثات حساب سابق بعد تبديل الحساب وإعادة تحميل البيانات من الخادم
- [x] تحديث عنوان المحادثة في قائمة Chats بعد أول رسالة بدلاً من إبقائه محادثة جديدة
- [x] إصلاح OpenAI streaming error 403 وتحويل مسار الاستدلال إلى مزود Hajeen/Groq المهيأ
- [x] إضافة اختبارات regression للعزل والعنوان ومسار النموذج وبناء APK جديد

## خطة الإصلاح الحالية

- [x] تأكيد تهيئة Facebook native ورفض الإعداد الناقص برسالة تشخيصية قابلة للفهم
- [x] إعادة ضبط حالة المحادثات عند تغيّر هوية الحساب وإجبار التحميل من namespace الحساب الحالي
- [x] مزامنة عنوان المحادثة وقائمة Chats بعد اكتمال أول رسالة
- [x] تمرير modelId إلى مسار Groq/Hajeen وعدم استخدام OpenAI غير المهيأ كمسار افتراضي
- [x] جعل أخطاء SSE النقلية أخطاء فعلية بدلاً من عرضها كنص مساعد
- [x] إضافة اختبارات regression وتشغيل اختبارات Flutter وBackend وبناء APK v1.0.3+5

## بلاغ اختبار إعادة فتح التطبيق وانقطاع الإنترنت — 2026-08-27

- [x] تشخيص سبب رسالة `Server returned status 502` عند تسجيل الدخول بالبريد بعد إعادة فتح التطبيق
- [x] تشخيص فشل رجوع Facebook OAuth بعد نجاح صفحة Facebook
- [x] إزالة سبب صمت زر Google والتحقق من حقن `GOOGLE_SERVER_CLIENT_ID` في APK المستخدم فعلياً
- [x] تحسين رسائل فشل الاتصال بعد انقطاع الإنترنت وإعادة المحاولة دون حالة تحميل عالقة
- [x] إضافة اختبارات regression لاستعادة الجلسة ومسارات 502 وOAuth بعد إعادة التشغيل
- [x] بناء APK إصلاحي جديد والتحقق من موارده واختباراته

## طلب مزامنة GitHub — 2026-08-27

- [x] مراجعة تغييرات Flutter الجديدة وملفات البناء قبل رفعها إلى فرع main
- [x] مراجعة تغييرات Backend الجديدة قبل رفعها إلى فرع master
- [x] التأكد من عدم تضمين الأسرار أو ملفات APK داخل commits GitHub
- [x] رفع Flutter إلى main وBackend إلى master
- [x] التحقق من تطابق الفروع المحلية والبعيدة وتوثيق commit IDs
