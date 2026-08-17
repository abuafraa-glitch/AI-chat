# Phase 10 — Brain Runtime Matrix

## الحكم العام

**BRAIN RUNTIME STATUS = NOT VERIFIED in the current workspace.** يوجد ملف `brain/brain_v3.py` ويعرض pipeline موحداً نظرياً، لكن استيراده لا يمكن إثباته في هذه الشجرة لأن عدة وحدات يستوردها غير موجودة في listing الحالي. وقد أزيل مسار ModelRouter النصي المحاكي أثناء Phase 10، وأصبح unknown provider يفشل مغلقاً، لكن runtime الكامل ما زال غير قابل للتحقق بسبب الوحدات المفقودة.

## مسار التنفيذ المعلن

`MemoryFabric → Policy → Intent → Goal → Context → Reasoning → Decision → ModelRouter → Memory persistence`.

ملف BrainV3 يستدعي `MemoryFabric` و`ModelRouter` و`PolicyEngine` وطبقات intent/context/reasoning وGoalManager وDecisionEngine، ثم يسجل `ExecutionTrace`. المسار يرفض الطلب عند فشل policy، ويرفع خطأ عند فشل ModelRouter، لكن بعض طبقات التحليل تسجل `skipped` وتتابع، ولذلك يلزم إثبات أن هذا السلوك مقصود في العقد وليس تجاوزاً لمرحلة لازمة.

## مصفوفة الإثبات

| المرحلة | EXISTS | IMPLEMENTED | INTEGRATED | CALLED | RUNTIME VERIFIED | TESTED | الدليل/المشكلة |
|---|---|---|---|---|---|---|---|
| BrainRequest/BrainResponse | نعم داخل `brain_v3.py` | نعم dataclasses | نعم مع process | نعم | جزئي | غير مثبت حالياً | imports الخارجية تمنع collection الكامل |
| ExecutionTrace | نعم | نعم | نعم في process | نعم | جزئي | غير مثبت حالياً | يسجل layers، لكن لا يسجل كل حقول decomposition/planning في `to_dict` |
| MemoryFabric | غير قابل للإثبات من listing الحالي | غير متاح في الشجرة الحالية | غير قابل للإثبات | Brain يستورده | لا | سابقاً focused فقط | مسار source الحالي لا يحتوي ملفات memory التي يتوقعها BrainV3 |
| PolicyEngine | غير موجود في listing الحالي | غير قابل للتحقق | Brain يستورده | نعم نظرياً | لا | لا | missing module path |
| Intent/Context/Reasoning | جزئي؛ `cognitive_layer` موجود لكنه لا يحتوي الملفات المطلوبة | غير قابل للتحقق | Brain يستوردها | نعم نظرياً | لا | لا | missing modules في الشجرة الحالية |
| GoalManager/TaskDecomposer | غير موجودان في listing الحالي | غير قابل للتحقق | Brain يستوردهما | نعم نظرياً | لا | لا | missing module path |
| DecisionEngine | غير موجود في listing الحالي | غير قابل للتحقق | Brain يستورده | نعم نظرياً | لا | لا | missing module path |
| ModelRouter | نعم `brain/model_router.py` | نعم | نعم مع BrainV3 | نعم في process | جزئي | تحقق fail-closed ناجح؛ full tests blocked | unknown provider now raises and route returns success=false |
| Provider boundary | جزئي | Ollama/OpenAI calls موجودة | Router يستخدمها | نعم | غير آمن بالكامل | لا | `provider.chat` يسمح registry؛ يلزم تحقق result وcontent |
| Memory persistence | غير قابل للتحقق | غير قابل للتحقق | Brain يضيف الرسائل | نعم نظرياً | لا | لا | MemoryFabric missing |

## تعارضات العقود

كان يوجد تعارض مباشر في `ModelRouter._call_model`: إذا لم يكن provider مسجلاً ولم يكن نوعه `ollama` أو `openai`، كان يعيد النص `استجابة محاكاة` بدلاً من فشل صريح. أزيل هذا المسار في Phase 10 وأصبح unknown provider يرفع `RuntimeError`، بينما تبقى قابلية تشغيل providers الحقيقية غير مثبتة.

كما أن `ModelRouter.select_model` يفضل النماذج المحلية افتراضياً، لكنه لا يتحقق من availability قبل اختيارها. `route` يحاول fallback إلى نماذج أخرى بعد الفشل، ثم يعيد `success=False` عند فشل الجميع. بعد الإصلاح لم يعد unknown provider قادراً على تحويل الفشل إلى نجاح نصي كاذب، لكن availability الفعلية للنماذج ما زالت غير مثبتة.

## عقود تحتاج تحققاً بعد استعادة الشجرة الكاملة

يجب تدقيق `LLMRequest` و`LLMResponse` و`BaseLLMProvider` و`InferenceEngine` و`LLMManager` و`ReasoningResult` وMemory contracts وPlanning contracts. هذه الرموز غير موجودة في listing الحالي أو غير قابلة للاستيراد، لذلك لا يجوز إعلان توافقها اعتماداً على الوثائق فقط.

## مراجع محلية

[1]: ../../../../phase10_brain_audit.txt "Brain and ModelRouter source audit"
[2]: ../../../../phase10_root_cause_scan.txt "Current import root-cause scan"
[3]: ../../../../phase10_current_regression.log "Current collection regression"
[4]: ../BASELINE.md "Phase 10 baseline"
