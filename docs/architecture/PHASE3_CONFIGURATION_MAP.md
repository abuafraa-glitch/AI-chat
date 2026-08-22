# Phase 3 — Configuration Map

## مصادر ظهرت في الجرد

`configs/`, `core/llm/config.py`, `core/model/model_config.py`, `brain/model_router.py`, `core/llm/llm_manager.py`, `monitoring/ai_metrics`, واختبارات Phase المختلفة.

| الإعداد | Canonical authority المرشح | Secondary/consumers | الحالة |
|---|---|---|---|
| `MODEL_ID` | `core/model/model_registry.py` metadata | Router/providers/configs | UNKNOWN حتى يُثبت مصدر runtime الوحيد |
| `PROVIDER` | `core/llm/provider_registry.py` | ModelRouter/LLMManager | CANONICAL CONTRACT، source النهائي PARTIAL |
| `DATABASE_URL` | `configs/`/database settings | API/services/workers | UNKNOWN |
| `REDIS_URL` | `configs/redis.py` | services/workers | CANONICAL CANDIDATE |
| `ENVIRONMENT` | settings/config modules | all services | UNKNOWN بسبب تعدد loaders |
| Security settings | `security/` + config | API/middleware | DOMAIN CANONICAL، authority UNKNOWN |
| Feature flags | config/monitoring/brain consumers | services | UNKNOWN |

## قرار

لا يُغير configuration behavior في Phase 3. المطلوب في المرحلة التالية إنشاء precedence table وstartup validation، مع رفض production إذا اختلف model/provider أو استُخدم test provider.


## مصادر الأدلة

- الالتزام المفحوص: `3268c262be9fb2fac9ed641d047857aa788e5566`.[1]
- الدليل الآلي: Import Graph وPhase 1/2 reports وRuntime Probes الموجودة في `docs/architecture/`.
- التصنيف المتحفظ: وجود الكود لا يساوي إثبات Runtime، ووجود اختبار وحدة لا يساوي إثبات E2E.

### References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/3268c262be9fb2fac9ed641d047857aa788e5566
