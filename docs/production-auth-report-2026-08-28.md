# تقرير تنفيذ مصادقة Production — Hajeen AI

## النتيجة

تم نقل المصادقة من التخزين المؤقت داخل الذاكرة إلى مخزن SQLAlchemy دائم، مع إبقاء مسارات Flutter الأساسية: التسجيل، الدخول، Google، Facebook، refresh، logout، revoke، me، verify-email، resend-verification، forgot-password، وreset-password.

## التغييرات الأساسية

| المجال | التنفيذ |
|---|---|
| التخزين | جداول `auth_users`, `auth_identities`, `auth_sessions`, `auth_codes`, `auth_throttles`. |
| كلمات المرور | bcrypt بدلاً من SHA-256، مع رفض كلمات المرور القصيرة. |
| الهوية الموحدة | مفتاح المزود والـsubject فريد، والبريد الموثق من المزود يربط الحساب القائم بدلاً من إنشاء حساب مكرر. |
| الجلسات | refresh JTI محفوظ في قاعدة البيانات، تدوير refresh، إبطال logout/revoke، وإبطال كل الجلسات عند reset. |
| البريد | OTP يرسل إلى البريد المطبع للمستخدم فقط؛ لا يوجد fallback إلى بريد المسؤول. |
| الحماية | رسائل عامة لمسارات forgot/login، انتهاء الرموز، حد محاولات OTP، ومنع إعادة الإرسال قبل 60 ثانية. |
| قاعدة البيانات | دعم SQLite للتطوير وMySQL عبر PyMySQL، مع `pool_pre_ping`. |
| Flutter | تحديث reset ليستخدم `code` و`new_password` مع بقاء واجهة AuthController العامة. |

## الاختبارات

نجحت مجموعة المصادقة المحددة: **13 اختباراً**، وتشمل اختبارات HTTP لعقد auth، التسجيل المعلق حتى OTP، resend والتقييد، تطبيع البريد، reset، bcrypt، refresh rotation، logout/revoke، واستمرارية الهوية.

فحص `compileall` نجح على طبقات API والأمان والدماغ. لم يتوفر Flutter SDK في البيئة الحالية (`dart` و`flutter` غير موجودين)، لذلك لم يمكن تشغيل `flutter test` أو بناء APK في هذه الجولة؛ التغيير المحمول محدود بسطر عقد request ويمكن مراجعته عند توفر SDK.

تشغيل مجموعة Backend الكاملة أظهر **1914 ناجحاً و38 فاشلاً و28 متجاوزاً**؛ معظم الإخفاقات قديمة وغير مرتبطة بالمصادقة، مثل اختبارات نماذج Groq، data-engine، CLI، والتنظيف. تم إصلاح اختبار auth boundary الذي كان يعتمد على admin fallback قديم ليستخدم fixture دائم داخل قاعدة البيانات.

## متطلبات النشر

يجب حقن `DATABASE_URL`, `JWT_SECRET`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, و`SMTP_FROM_EMAIL` في بيئة staging/production. يجب تشغيل migration/إنشاء الجداول في نافذة نشر مضبوطة قبل تشغيل عدة نسخ. لا تُنقل كلمات مرور SHA-256 القديمة إلى bcrypt؛ الحسابات القديمة تحتاج reset أو migration-on-login معتمدة أمنياً.

لا تُعتبر تكاملات Google/Facebook وSMTP الحية مثبتة حتى تُشغّل في staging بتوكنات حقيقية وأسرار injected، دون حفظها في Git.
