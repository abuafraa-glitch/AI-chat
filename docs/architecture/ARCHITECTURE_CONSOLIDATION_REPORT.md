# Architecture Consolidation Report — Phase 1

## A. Executive Summary

نُفذت هذه المرحلة على فرع `master` عند الالتزام `3268c262be9fb2fac9ed641d047857aa788e5566`. التزمت العملية بالقيود المطلوبة: لم تُحذف ملفات، ولم تُنقل أو تُعاد تسميتها، ولم يتغير منطق التشغيل، ولم يبدأ التدريب، ولم يُنزّل نموذج Qwen، ولم تُرفع أوزان إلى Git. التغيير الوحيد المقصود هو إنشاء وثائق التدقيق الخمس داخل `docs/architecture/`.

المستودع يحتوي فعلياً على طبقات API وAuthentication وBrainV3 وMemory وRAG وData Engine وModelRegistry وModelRouter وRuntime وAgents وWorkers وSecurity وMonitoring وInfrastructure وTests. لذلك لا يصح وصف المكونات المركزية بأنها غير موجودة. في الوقت نفسه، وجود الكود لا يساوي ثبوت التكامل أو التشغيل أو الجاهزية الإنتاجية. الدليل الحالي قوي في بعض اختبارات BrainV3 وعقد VERIFIED_BASE، لكنه لا يثبت بعد مساراً حقيقياً من المستخدم إلى Qwen3-30B-A3B ثم العودة بالاستجابة.

## B. Current Architecture

المعمارية الحالية متعددة الطبقات، لكنها تطورت تراكمياً؛ ولذلك توجد أكثر من واجهة أو تنفيذ محتمل لبعض الوظائف. مسار المحادثة الظاهر في الكود يمر عبر FastAPI أو WebSocket، ثم أحد مسارات AI chat، ثم `ChatService` أو BrainV3، وبعد ذلك طبقات الذاكرة وRAG والأدوات بحسب نوع الطلب، ثم ModelRouter ومزود LLM/runtime، ثم الاستجابة.

المعمارية الفعلية ليست 27 مجلداً منفصلاً، ولا ينبغي تحويل التقسيم الوظيفي إلى إعادة تنظيم قسرية. التقسيم الآمن الآن هو إبقاء الملفات في أماكنها، وتحديد مصدر الحقيقة والواجهة الرسمية لكل وظيفة، ثم توحيد المسارات تدريجياً في مرحلة لاحقة.

## C. Ownership

توجد خريطة الملكية التفصيلية في `OWNERSHIP_MAP.md`. أهم القرارات الحالية هي أن `brain/brain_v3.py` هو المرشح الرسمي لملكية Brain، و`core/model/model_registry.py` هو مصدر الحقيقة لسجل النماذج، و`brain/model_router.py` هو سلطة اختيار النموذج، و`services/chat/chat_service.py` هو حد orchestration للمحادثة. أما الذاكرة وRAG والتخزين والنماذج وواجهات المحادثة فما زالت تحتوي على مسارات متداخلة تحتاج consolidation لاحقاً.

## D. Duplicate Components

أظهر التحليل الساكن 791 ملف Python و8,111 تعريفاً و607 أسماء أصناف أو دوال متكررة في أكثر من موضع. هذا رقم تدقيق وليس حكماً بأن كل تكرار خطأ؛ فقد تكون بعض التكرارات اختبارات أو adapters أو bounded contexts. تم تسجيل التكرارات المرشحة في `DUPLICATE_COMPONENTS.md`، خصوصاً Memory وModel وLLM وInference وStorage وRAG وAgents وSecurity وPromptBuilder وBrain وConfiguration وData services.

القرار في هذه المرحلة هو `CONSOLIDATE_LATER` وليس الحذف. لا يجوز إزالة أي مسار قبل معرفة جميع المستدعين ونقل الاختبارات وتوفير واجهة توافقية عند الحاجة.

## E. Runtime Call Graph

المسار المثبت من الكود هو:

```text
Client
  → FastAPI/WebSocket
  → Auth/Dependencies
  → AI Chat Route
  → ChatService أو BrainV3
  → Memory/RAG/Tools حسب القدرة
  → ModelRouter
  → ModelRegistry للتحقق والاختيار
  → Provider/Runtime
  → Inference
  → Policy/Audit/Post-processing
  → JSON/SSE/WebSocket Response
```

وجود الانتقال في الكود لا يعني أن runtime الحقيقي نجح. تفاصيل الحالات `PROVEN` و`PARTIAL` و`NOT_PROVEN` موجودة في `CALL_GRAPH.md`.

## F. Model Path

مسار Hajeen الحالي محفوظ على مستوى العقد والـregistry والـrouter:

```text
Hajeen Contract / Manifest
  → ModelRegistry.register_verified_base()
  → ModelRouter integrity and eligibility checks
  → Hajeen Provider / Runtime
  → Qwen3-30B-A3B artifact
  → Inference
```

القيم المرجعية المعتمدة هي `Qwen/Qwen3-30B-A3B` مع source revision `ad44e777bcd18fa416d9da3bd8f70d33ebb85d39`، ومستودع الهدف `Raedthawaba/hajeen-base-qwen3-30b-a3b` مع target commit `9d6a564f66303a3691cbb646d39a28f3eb792ca7`. لا توجد أوزان داخل Git، وهذا مطابق للمتطلب الأمني.

يجب فصل أربع حالات: تحقق الـartifact، تحقق runtime، تحقق inference، وتحقق التدريب. الحالة الحالية تثبت عقد artifact والـsharded manifest في الاختبارات، لكنها لا تثبت تحميل Qwen في GPU أو توليد إجابة حقيقية أو قدرة تدريب.

## G. Test Status

نتيجة `pytest --collect-only` الحالية هي جمع 1,864 اختباراً ثم التوقف بخطأ واحد أثناء collection. الخطأ مرتبط بتهيئة `sentence-transformers/all-MiniLM-L6-v2` وعدم العثور على ملف `pytorch_model.bin` أو `model.safetensors` مع ظهور إخفاقات لاحقة في embedding stage. السبب يحتاج عزلاً بين dependency وnetwork وcache وinitialization وfixture؛ لا ينبغي إصلاح الاختبارات عشوائياً.

النتائج المستهدفة المهمة هي: 3 اختبارات ناجحة لعقد Verified Base، و6 اختبارات ناجحة لـBrainV3 cognitive، و30 اختباراً ناجحاً لـAI chat، و3 اختبارات ناجحة لـAPI health. كما أن الأمر الانتقائي الأوسع سجل 49 نجاحاً و4 إخفاقات و17 خطأ، منها مشاكل API workflow وChannel Registry، لذلك لا يجوز تعميمها على ModelRegistry أو BrainV3.

## H. Production Readiness

مصفوفة الجاهزية التفصيلية موجودة في `READINESS_MATRIX.md`. النتيجة المهنية ليست رقماً عاماً غير قابل للتدقيق؛ بل حالات لكل مكون. الخلاصة أن أجزاء كثيرة في مستوى Code وIntegration، وبعضها في مستوى Unit/Integration Tests، لكن Runtime وE2E للنموذج الحقيقي غير مثبتين. لذلك تبقى المنصة **غير جاهزة للإطلاق العام**، مع كونها قاعدة Pre-production متقدمة.

## I. Risks

أكبر المخاطر هي فشل test collection بسبب تهيئة embeddings، وجود مسارات محادثة متعددة، تكرار الذاكرة وRAG وInference والتكوين، عدم إثبات عزل المستأجرين في E2E، عدم إثبات runtime GPU للنموذج، احتمال وجود fallback في مسارات غير إنتاجية، وعدم إثبات النشر والاستعادة فعلياً. توجد أيضاً تحذيرات deprecation في FastAPI وPydantic وpytest-asyncio ينبغي جدولتها، لكنها ليست وحدها مانع الإطلاق.

## J. Recommended Consolidation

المرحلة التالية ينبغي أن تنفذ Architecture Inventory أعمق بالاستيرادات والـcall graph والتتبع، ثم تختار مصدراً واحداً لكل وظيفة. الأولوية هي تثبيت واجهة API للمحادثة، جعل BrainV3 حد التنسيق الرسمي، جعل ModelRouter سلطة النماذج الوحيدة، تثبيت ModelRegistry كمصدر حقيقة، وتحديد facade واحد للذاكرة وRAG وRuntime.

بعد ذلك يجب إصلاح collection gate، ثم اختبار Auth وAuthorization وTenant isolation، ثم إثبات API إلى BrainV3، ثم BrainV3 إلى Memory/RAG/Tools، ثم Router إلى Provider وRuntime، ثم تشغيل inference الحقيقي على GPU مناسب.

## K. Recommended Deletions

لا توجد توصية حذف قابلة للتنفيذ في Phase 1. توجد مرشحات محتملة في `DUPLICATE_COMPONENTS.md`، لكن أي حذف يجب أن يأتي بعد ownership map محدث، ومراجعة جميع imports، واختبارات بديلة، ومرحلة deprecation، وخطة rollback. لذلك كل المرشحات حالياً `KEEP` أو `CONSOLIDATE_LATER`.

## L. Next Phase

المرحلة التالية المقترحة هي Architecture Consolidation Phase 2، وتبدأ بإنشاء call edges موثقة لكل مكون، ثم إضافة runtime probes غير تغييرية، ثم إصلاح سبب embeddings collection، ثم بناء اختبار E2E مصطنع بمزود آمن للاختبار، وأخيراً اختبار Hajeen الحقيقي عندما تتوفر بيئة GPU وartifact خارج Git. لا يبدأ التدريب ولا تنزيل Qwen قبل اكتمال هذا الدليل.

## Files created in this phase

| File | Purpose |
|---|---|
| `docs/architecture/OWNERSHIP_MAP.md` | مالك كل مكوّن وواجهته ومستدعوه وحالته |
| `docs/architecture/CALL_GRAPH.md` | مسار الاستدعاء المثبت وغير المثبت |
| `docs/architecture/READINESS_MATRIX.md` | مصفوفة قابلة للقياس للجاهزية |
| `docs/architecture/DUPLICATE_COMPONENTS.md` | سجل التكرارات وقراراتها المؤقتة |
| `docs/architecture/ARCHITECTURE_CONSOLIDATION_REPORT.md` | التقرير التنفيذي الكامل |

## References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/master/docs/architecture "Architecture Phase 1 documents"
[2]: https://github.com/abuafraa-glitch/AI-chat/blob/master/brain/brain_v3.py "BrainV3 source"
[3]: https://github.com/abuafraa-glitch/AI-chat/blob/master/brain/model_router.py "ModelRouter source"
[4]: https://github.com/abuafraa-glitch/AI-chat/blob/master/core/model/model_registry.py "ModelRegistry source"
[5]: https://github.com/abuafraa-glitch/AI-chat/tree/master/tests "Test suites"
