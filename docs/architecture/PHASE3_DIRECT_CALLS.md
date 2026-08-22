# Phase 3 — Direct Calls Audit

الجدول التالي يسجل الاستدعاءات التي ظهرت خارج المالك الرسمي أو التي تحتاج تدقيقاً إضافياً. لم تُصلح تلقائياً.

| الملف/النطاق | الاستدعاء | التصنيف | الخطر | الهدف اللاحق |
|---|---|---|---|---|
| `api/v1/ai/*` | إنشاء/تنسيق ChatRequest وcompletion | COMPATIBILITY | تعدد public routes | تحويل تدريجي إلى ChatService |
| `api/v1/hajeen_model_router.py` | مسار Hajeen API مستقل | COMPATIBILITY/UNKNOWN | احتمال تجاوز ChatService أو Brain boundary | Adapter موثق ثم trace |
| `workers/tasks/inference_tasks.py` | استدعاء `get_chat_service().chat` | ALLOWED | worker boundary يحتاج context | إبقاؤه مع request/tenant metadata |
| `services/inference_service.py` | استخدام `LLMManager` | ALLOWED | طبقة inference لا تمر دائماً من Router | إثبات caller graph |
| `core/llm/providers/*` | provider implementations | ALLOWED داخل Provider layer | تعدد providers | توحيد BaseLLMProvider/Registry |
| `hajeen_model/inference/*` | Hajeen-specific provider/engine | COMPATIBILITY | مساران provider وruntime | Adapter خلف ProviderContract |
| `workers/distributed/gpu_worker.py` | `model.generate` | UNKNOWN/VIOLATION CANDIDATE | استدعاء runtime مباشر خارج Router محتمل | ربطه بعقد Runtime أو تسجيله كworker exception |
| `services/rag/*` | retriever/prompt/context calls | ALLOWED داخل RAG | تعدد retrievers/builders | Retrieval Facade |
| `core/memory/*`, `services/memory/*` | memory managers/services | UNKNOWN | تعدد واجهات وbackends | Memory Facade وtrace |
| `api/main.py` | storage/redis/rag wiring | UNKNOWN | composition root واسع | فصل wiring عن business logic لاحقاً |

## حدود النتيجة

لا يثبت هذا الجدول أن كل حالة `UNKNOWN` مخالفة. يلزم Runtime Trace أو tests مخصصة لإثبات caller وسياق الصلاحيات قبل أي إصلاح.


## مصادر الأدلة

- الالتزام المفحوص: `3268c262be9fb2fac9ed641d047857aa788e5566`.[1]
- الدليل الآلي: Import Graph وPhase 1/2 reports وRuntime Probes الموجودة في `docs/architecture/`.
- التصنيف المتحفظ: وجود الكود لا يساوي إثبات Runtime، ووجود اختبار وحدة لا يساوي إثبات E2E.

### References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/3268c262be9fb2fac9ed641d047857aa788e5566
