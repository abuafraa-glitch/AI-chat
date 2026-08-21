# Duplicate Components Register

> هذا سجل تدقيق وليس قائمة حذف. لا يوجد حذف أو نقل أو إعادة تسمية في Phase 1.

## معيار التصنيف

| التصنيف | المعنى |
|---|---|
| `CANONICAL` | المرشح الحالي لمصدر الحقيقة، بناءً على الاستدعاءات والواجهة المركزية. |
| `SECONDARY` | تنفيذ أو واجهة ما زالت مستخدمة أو قد تكون مساندة. |
| `LEGACY` | مسار توافق أو تاريخي يجب عدم توسيعه. |
| `DUPLICATE` | تكرار مثبت في الاسم أو الوظيفة، ويحتاج مراجعة المستدعين قبل الإزالة. |
| `UNKNOWN` | لا يكفي الدليل الحالي لتحديد الدور. |

## السجل

| الوظيفة | Canonical candidate | Secondary / Legacy candidates | دليل التكرار | قرار Phase 1 |
|---|---|---|---|---|
| Memory | `brain/memory/` | `core/memory/`, `services/memory/` | أسماء ووظائف ذاكرة متعددة ومراجع متفرقة | `CONSOLIDATE_LATER`; لا حذف |
| Model selection | `brain/model_router.py` | `core/llm/llm_manager.py` compatibility facade، مزودات متعددة | LLM manager يصرح أن Router هو authority، مع واجهات اختيار قديمة | Router canonical; compatibility remains |
| Model registry | `core/model/model_registry.py` | learning/legacy registry references | أكثر من مسار lifecycle حول registry | Registry canonical; inspect lifecycle |
| LLM providers | `core/llm/providers/` | `services/distributed_inference/` and provider managers | أكثر من طبقة provider/runtime | Provider boundary needs one production contract |
| Inference | `core/llm/`, runtime modules | distributed inference modules | أكثر من تنفيذ وتسمية للـinference | Select after runtime proof |
| RAG/retrieval | `core/retrieval/` | `services/rag/`, API search routes | retrieval/context/citation spread over layers | Define retrieval facade later |
| Storage | `storage/` | `database/`, `storage_data/`, service data adapters | multiple persistence responsibilities | Separate ownership by data type |
| Agents | `services/agents/` | `agent_frameworks/` | orchestrator/planner/framework overlap | Keep; designate orchestrator |
| Security | `security/` | API dependency/policy modules | enforcement points exist in more than one layer | Security remains policy owner |
| Prompt building | unified prompt builder paths | prompt modules under Brain/LLM | `PromptBuilder` appears across 23 Python files | Find canonical builder and adapter later |
| Brain | `brain/brain_v3.py` | evolution/reflection/decision compatibility paths | BrainV3 plus legacy/evolution imports | BrainV3 canonical; compatibility retained |
| Data services | `data_engine/` | `services/data_service` and ingestion connectors | ingestion and service APIs overlap | Map jobs and source of truth |
| Configuration | `configs/` | settings loaders distributed in modules | multiple settings/config access points | Consolidate configuration authority later |
| Chat routes | `api/v1/ai/chat.py` | `api/v1/ai/router.py`, `api/v1/hajeen_model_router.py`, WebSocket | multiple chat route surfaces | Preserve compatibility; choose one public contract |

## Evidence from static analysis

The repository contains 791 Python files, 8,111 AST definitions, and 607 duplicated definition names (same class or function name in more than one location). These numbers are **signals for review**, not proof that every occurrence is a harmful duplicate. A class name may legitimately be repeated in tests, adapters, or separate bounded contexts.

The following references were observed across the codebase: `BrainV3` in 23 files, `ModelRouter` in 18, `ModelRegistry` in 8, `RAG` in 48, `Storage` in 39, `PromptBuilder` in 23, and `MemoryFabric` in 17. The next phase must use import edges and runtime traces before any deletion decision.

## Required next decision per duplicate

For every row, the consolidation phase must identify the public interface, enumerate callers, add compatibility adapters if needed, migrate tests, and only then consider deprecation. No file is removable based on folder names or duplicate class names alone.

## References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/master/brain "Brain sources"
[2]: https://github.com/abuafraa-glitch/AI-chat/tree/master/core "Core sources"
[3]: https://github.com/abuafraa-glitch/AI-chat/tree/master/services "Service sources"
