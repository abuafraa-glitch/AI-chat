# Phase 3 — Canonical Architecture

## Executive decision

تم تحديد المالك الرسمي حيث توجد أدلة كافية، واستُخدم `UNKNOWN` عندما لا يسمح Import Graph أو Runtime Evidence أو الاختبارات باختيار implementation واحد بثقة. لم تُحذف أو تُنقل أو تُعاد تسمية أي implementation.

| الوظيفة | Canonical owner | التصنيف | القرار والدليل |
|---|---|---|---|
| API | `api/main.py` و`api/v1/` | CANONICAL | بوابة HTTP والمسارات العامة؛ توجد اختبارات API وHealth. |
| Authentication | `security/auth/` مع `api/v1/auth/` | CANONICAL/SECONDARY | طبقة الأمن موجودة، لكن E2E الكامل غير مثبت. |
| Authorization | `security/authorization/` و`security/permissions/` | UNKNOWN | توجد عدة نقاط enforcement؛ يلزم trace لكل endpoint. |
| Tenant Context | `multi_tenant/` | UNKNOWN | توجد مكونات tenant وquota، لكن مصدر identity والعزل الكامل غير مثبت. |
| Conversation | `services/chat/chat_service.py` | CANONICAL | `ChatService` هو orchestration boundary، مع routes بديلة موثقة. |
| Brain | `brain/brain_v3.py` | CANONICAL | `HajeenBrainV3.process/stream/get_brain_v3` مثبتة في probes والاختبارات. |
| Memory | `brain/memory/unified_interface.py` | CANONICAL FACADE | واجهة توحيد ظاهرة؛ implementations متعددة، والـbackend النهائي UNKNOWN. |
| Retrieval/RAG | `core/retrieval/retrieval_engine.py` | CANONICAL FACADE CANDIDATE | عقد RetrievalEngine واضح، مع retrievers متعددة في `services/`. |
| Tools | `services/tools/` و`services/agents/` | UNKNOWN | الملكية بين registry والتنفيذ والصلاحيات لم تثبت كمسار واحد. |
| Agents | `services/agents/` | CANONICAL CANDIDATE | توجد agent modules واختبارات، لكن orchestration النهائي يحتاج E2E. |
| Model Registry | `core/model/model_registry.py` | CANONICAL | مصدر هوية وحالة artifact والـmanifest، وليس inference. |
| Model Router | `brain/model_router.py` | CANONICAL | مصدر اختيار النموذج وfail-closed للمسار المحلي. |
| LLM Provider | `core/llm/base.py` + `core/llm/provider_registry.py` | CANONICAL CONTRACT | providers متعددة؛ registry/base هما العقد، وليس provider بعينه. |
| Runtime/Inference | `core/inference_engine/` و`services/inference_service.py` | UNKNOWN | توجد طبقات متعددة؛ Qwen Runtime NOT_PROVEN. |
| Prompt Builder | `brain/prompts/unified_prompt_builder.py` | CANONICAL CANDIDATE | أعلى ارتباطاً بـBrain؛ builders أخرى موثقة كـsecondary. |
| Data Ingestion | `data_engine/ingestion/` | CANONICAL | crawlers/connectors ومسار ingestion موجود. |
| Data Processing | `data_engine/processing/` | CANONICAL | cleaning/transformation موجودان، مع workers ومسارات مساندة. |
| Embeddings | `core/embeddings/` و`data_engine/ai/embeddings/` | UNKNOWN | تكرار واضح وفشل بيئي سابق؛ لا يختار Phase 3 implementation نهائياً. |
| Storage | `data_engine/storage/` | UNKNOWN | relational/object/vector/cache/artifact متداخلة؛ يلزم ownership map. |
| Configuration | `core/llm/config.py` و`configs/` | UNKNOWN | مصادر إعدادات متعددة؛ لا يُغير behavior في Phase 3. |
| Security/Policy | `security/` | CANONICAL DOMAIN | المجال الرسمي، مع حدود فرعية تحتاج تثبيتاً. |
| Workers/Tasks | `workers/` | CANONICAL DOMAIN | entrypoints موجودة، لكن idempotency وDLQ ليست مثبتة لكل مهمة. |
| Monitoring/Audit | `monitoring/` و`security/audit/` | CANONICAL DOMAIN | الفرق بين metrics/logs/audit يحتاج توثيقاً تشغيلياً. |
| Training/Evaluation | `hajeen_model/training/` و`evaluation/` | CANONICAL DOMAIN | منفصل عن inference؛ لم يبدأ تدريب. |

## قاعدة الملكية

المالك الرسمي مسؤول عن العقد والاتساق، لا عن ابتلاع كل الوظائف. أي implementation آخر يبقى `SECONDARY` أو `ADAPTER` أو `LEGACY` حتى تُثبت الاستدعاءات وقرار الهجرة.


## مصادر الأدلة

- الالتزام المفحوص: `3268c262be9fb2fac9ed641d047857aa788e5566`.[1]
- الدليل الآلي: Import Graph وPhase 1/2 reports وRuntime Probes الموجودة في `docs/architecture/`.
- التصنيف المتحفظ: وجود الكود لا يساوي إثبات Runtime، ووجود اختبار وحدة لا يساوي إثبات E2E.

### References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/3268c262be9fb2fac9ed641d047857aa788e5566
