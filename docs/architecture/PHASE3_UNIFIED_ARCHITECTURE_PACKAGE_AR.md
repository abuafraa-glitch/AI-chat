# Architecture Consolidation Phase 3

> وثيقة موحدة تجمع التقرير والخرائط الأساسية لمرحلة Phase 3.

---

# 1. التقرير النهائي

# Phase 3 Final Report — Canonicalization, Authority & Compatibility

## A. Executive Summary

تم تنفيذ Canonicalization توثيقية على فرع `master` دون حذف أو نقل أو إعادة تسمية أو تغيير بنية التشغيل. تم اعتماد BrainV3 وChatService وModelRegistry وModelRouter وعقد Provider كمصادر رسمية أو مرشحين رسميين حيث تسمح الأدلة. أما Memory وRAG وEmbeddings وStorage وConfiguration وTenant Isolation فبقيت جزئياً `UNKNOWN` بدلاً من اختراع قرار غير مثبت.

## B–C. Canonical architecture and ownership

| component | القرار | المالك | مستوى الدليل |
|---|---|---|---|
| Brain | CANONICAL | `brain/brain_v3.py` | probes + tests |
| Conversation | CANONICAL | `services/chat/chat_service.py` | tests + callers |
| Model Registry | CANONICAL | `core/model/model_registry.py` | contract tests |
| Model Router | CANONICAL | `brain/model_router.py` | probes + fail-closed tests |
| Provider | CANONICAL CONTRACT | `core/llm/base.py`/registry | contract tests |
| Memory | FACADE CANDIDATE / backend UNKNOWN | `brain/memory/unified_interface.py` | code + partial tests |
| Retrieval | FACADE CANDIDATE | `core/retrieval/retrieval_engine.py` | unit + partial integration |
| Prompt | CANDIDATE | `brain/prompts/unified_prompt_builder.py` | inventory + tests |
| Tenant | UNKNOWN | `multi_tenant/` + security | not fully E2E |

## D–E. Contracts and direct calls

العقود موثقة في `PHASE3_INTERFACE_CONTRACTS.md`. سجل direct calls في `PHASE3_DIRECT_CALLS.md` يحدد حالات `ALLOWED`, `COMPATIBILITY`, `UNKNOWN` و`VIOLATION CANDIDATE` دون إصلاح تلقائي.

## F–J. Consolidation decisions

Memory: facade candidate مع backend UNKNOWN. RAG: RetrievalEngine facade candidate وretrievers متخصصة. Prompt: UnifiedPromptBuilder candidate، وRAG builder adapter. Storage: typed ownership غير محسوم. Configuration: لا يوجد authority وحيد مثبت لكل key.

## K. Tenant Isolation

توجد مكونات multi-tenant وquota وsecurity، لكن لم يثبت Phase 3 أن `tenant_id` يأتي دائماً من identity موثقة في كل مسار. الحالة `NOT_PROVEN`، ويجب منع أي claim أقوى من الأدلة.

## L–M. Deprecation and migration

لا يوجد حذف. المرشحون موثقون مع صعوبة ومخاطر ومسار adapter في `PHASE3_DEPRECATION_CANDIDATES.md` و`PHASE3_MIGRATION_PLAN.md`.

## N–O. Tests and regressions

| البوابة | النتيجة |
|---|---|
| compileall | PASS |
| pytest collection | PASS، 1908 حالات مجمعة في Phase 2 baseline |
| Phase 2 final suite | 112 PASS، 2 SKIPPED، 6 warnings |
| Runtime probes | 7 PASS |
| Qwen runtime/inference | NOT_PROVEN |
| Training | NOT_STARTED |
| Phase 3 regression | لا تغيير تشغيلي مقصود؛ يجب إعادة regression suite بعد commit |

`SKIPPED` ليست نجاحاً، وغياب GPU يمنع claim عن Qwen Runtime.

## P. Remaining risks

أعلى المخاطر هي تعدد memory/prompt/retrieval/provider/config implementations، direct model generation محتمل في GPU worker، عدم إثبات tenant isolation لكل endpoint، وتعدد composition wiring.

## Q. Deferred work

تأجلت إزالة legacy، نقل الملفات، توحيد schema، تنزيل Qwen، GPU deployment، inference الحقيقي، training، وlarge refactor.

## R. Phase 4 recommendation

لا تبدأ Phase 4 كحذف أو refactor شامل. إن أُجيزت، تبدأ بـ contract hardening وtenant/security E2E وtyped configuration authority وdirect-call adapters، ثم regression. أي إزالة يجب أن تكون phase مستقلة بموافقة صريحة.

## Status

Phase 3: **COMPLETED AS DOCUMENTATION AND EVIDENCE**.

Phase 3: **NOT_PROVEN** بالنسبة لاختيار implementation نهائي للذاكرة وRAG وEmbeddings وStorage وConfiguration وTenant Isolation، وبالنسبة لـQwen Runtime/Inference.


## مصادر الأدلة

- الالتزام المفحوص: `3268c262be9fb2fac9ed641d047857aa788e5566`.[1]
- الدليل الآلي: Import Graph وPhase 1/2 reports وRuntime Probes الموجودة في `docs/architecture/`.
- التصنيف المتحفظ: وجود الكود لا يساوي إثبات Runtime، ووجود اختبار وحدة لا يساوي إثبات E2E.

### References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/3268c262be9fb2fac9ed641d047857aa788e5566


---

# 2. المعمارية Canonical

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


---

# 3. عقود الواجهات

# Phase 3 — Interface Contracts

هذه عقود توثيقية مبنية على الواجهات الحالية؛ لم تُنشأ abstractions Python جديدة.

| العقد | الواجهة الحالية | المدخلات/المخرجات | الحالة |
|---|---|---|---|
| ConversationContract | `ChatService.chat/stream` و`ChatRequest/ChatResponse` | رسالة وسياق → response أو stream | PROVEN جزئياً |
| BrainContract | `HajeenBrainV3.process/stream` | `BrainRequest` → `BrainResponse`/chunks | PROVEN عبر probes |
| MemoryContract | `UnifiedMemoryInterface` و`MemoryManager` | session/key/message → store/recall | FACADE PROVEN، backend UNKNOWN |
| RetrievalContract | `RetrievalEngine` و`SemanticRetriever` | query/top_k → hits/context | UNIT PROVEN، E2E PARTIAL |
| ModelRegistryContract | `ModelRegistry` | model identity/artifact/status → eligibility | PROVEN في الاختبارات المستهدفة |
| ModelRouterContract | `ModelRouter.route/stream/select_model` | messages/capability/budget → RouteResult/stream | PROVEN في probes |
| ProviderContract | `BaseLLMProvider` و`LLMRequest/Response` | request → response/stream | PROVEN بالعقود |
| InferenceContract | `InferenceService.generate/stream` | prompt/messages → text/chunks | CODE_EXISTS، runtime PARTIAL |
| ToolContract | schemas/registry/execution في `services/agents` و`services/tools` | validated args → result | UNKNOWN E2E |
| TenantContextContract | `multi_tenant/` وsecurity context | identity → tenant/user/resource ownership | NOT_PROVEN كاملاً |
| RelationalStorageContract | repositories/database modules | structured records → transactions | PARTIAL |
| ObjectStorageContract | storage/file modules | bytes + metadata → object ref | PARTIAL |
| VectorStorageContract | vector store managers/retrievers | vectors + metadata → hits | PARTIAL |

## قواعد العقد

يجب أن يمر الطلب المعرفي من Brain إلى ModelRouter، وأن يستشير Router الـRegistry، ثم يستخدم Provider/Runtime. لا يُسمح اعتبار `VERIFIED_BASE` دليلاً على Runtime أو inference.


## مصادر الأدلة

- الالتزام المفحوص: `3268c262be9fb2fac9ed641d047857aa788e5566`.[1]
- الدليل الآلي: Import Graph وPhase 1/2 reports وRuntime Probes الموجودة في `docs/architecture/`.
- التصنيف المتحفظ: وجود الكود لا يساوي إثبات Runtime، ووجود اختبار وحدة لا يساوي إثبات E2E.

### References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/3268c262be9fb2fac9ed641d047857aa788e5566


---

# 4. الاستدعاءات المباشرة

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


---

# 5. خطة الترحيل

# Phase 3 — Migration Plan

## المسار الموحد لكل تكرار

`Current → Compatibility Adapter → Canonical → Migrate callers → Tests → Deprecation → Future removal`.

| المسار | الخطوة التالية | معيار النجاح | المخاطر |
|---|---|---|---|
| Chat routes → ChatService | trace direct routes ثم adapter | كل public request يملك ChatService boundary | breaking API |
| Brain legacy → BrainV3 | caller inventory ثم adapter | no hidden BrainV2 callers | behavior regression |
| Memory implementations → facade | contract comparison وtenant tests | Brain لا يعرف implementation | data loss/privacy |
| RAG retrievers → Retrieval Facade | preserve specialized adapters | ranking/citations unchanged | quality regression |
| Prompt builders → unified builder | snapshot/prompt regression tests | one public prompt contract | prompt drift |
| Providers → BaseLLMProvider/Registry | direct call audit | providers resolved through registry/router | bypass/fallback |
| Runtime → InferenceContract | contract probes ثم GPU test | runtime failure is explicit | resource/latency |
| Storage types → typed ownership | inventory only ثم adapters | DB/Object/Vector/Cache/Artifact separated | persistence break |
| Config loaders → authority | precedence table + startup check | one source per key | deployment break |
| Tenant context → verified identity | security tests | tenant_id not client-trusted | isolation breach |

## ما لا يُنفذ الآن

لا حذف، لا نقل، لا rename، لا schema migration، لا Qwen download، لا GPU deployment، لا training.


## مصادر الأدلة

- الالتزام المفحوص: `3268c262be9fb2fac9ed641d047857aa788e5566`.[1]
- الدليل الآلي: Import Graph وPhase 1/2 reports وRuntime Probes الموجودة في `docs/architecture/`.
- التصنيف المتحفظ: وجود الكود لا يساوي إثبات Runtime، ووجود اختبار وحدة لا يساوي إثبات E2E.

### References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/3268c262be9fb2fac9ed641d047857aa788e5566

