# Phase 3 — Prompt Builder Map

## Inventory

| implementation | التصنيف الأولي | الملاحظات |
|---|---|---|
| `brain/prompts/unified_prompt_builder.py` — `UnifiedPromptBuilder` | CANONICAL CANDIDATE | أقرب إلى Brain، ومرتبط باختبار المسار الموحد. |
| `core/prompts/prompt_builder.py` — `PromptBuilder` | SECONDARY/UNKNOWN | عقد عام منخفض المستوى؛ يحتاج callers. |
| `services/prompts/prompt_builder.py` — `PromptBuilder` | SECONDARY | service-level builder وله `BuiltPrompt` مكرر الاسم. |
| `services/rag/prompt_builder.py` — `PromptBuilder` | ADAPTER/SPECIALIZED | خاص بسياق RAG ولا ينبغي دمجه قسراً. |
| `services/prompts/template_engine.py` — `PromptTemplate` | SUPPORTING | template engine لا يساوي builder. |
| `services/prompts/system_prompt_manager.py` | SUPPORTING | إدارة system prompts وسياسات، وليست builder كاملة. |
| `core/prompts/system_prompts.py` | SUPPORTING | مكتبة system prompts. |
| `brain/brain_v3.py` | DIRECT_PROMPT_CONSTRUCTION CANDIDATE | توجد مؤشرات prompt في Brain؛ يجب نقلها لاحقاً إلى builder الرسمي دون تغيير الآن. |

## القرار

المالك المرشح هو `UnifiedPromptBuilder`، لكن الحالة النهائية تبقى `CANONICAL CANDIDATE` إلى أن يثبت trace أن Brain وChat وRAG يستخدمونه فعلياً. builders الأخرى تبقى `SECONDARY` أو `ADAPTER`، ولا تُحذف.

## Migration

`Current builder → compatibility adapter → UnifiedPromptBuilder → migrate callers → tests → deprecate later`.


## مصادر الأدلة

- الالتزام المفحوص: `3268c262be9fb2fac9ed641d047857aa788e5566`.[1]
- الدليل الآلي: Import Graph وPhase 1/2 reports وRuntime Probes الموجودة في `docs/architecture/`.
- التصنيف المتحفظ: وجود الكود لا يساوي إثبات Runtime، ووجود اختبار وحدة لا يساوي إثبات E2E.

### References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/3268c262be9fb2fac9ed641d047857aa788e5566
