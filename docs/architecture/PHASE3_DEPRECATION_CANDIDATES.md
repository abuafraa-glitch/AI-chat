# Phase 3 — Deprecation Candidates

لا توجد حالة `DELETE` في هذه المرحلة. كل عنصر أدناه يحتاج migration evidence قبل deprecation.

| component/path | الوضع | replacement | الصعوبة | المخاطر | الاختبارات | removal phase |
|---|---|---|---|---|---|---|
| `core/memory/*` managers | UNKNOWN/SECONDARY | Memory Facade | عالية | فقدان persistence/خصوصية | memory tests | future approved |
| `services/memory/*` services | UNKNOWN/SECONDARY | Memory Facade | عالية | كسر session/vector behavior | service/integration | future approved |
| `services/retrieval/*` specialized retrievers | KEEP/SECONDARY | Retrieval Facade | متوسطة | اختلاف ranking | RAG tests | future approved |
| `core/prompts/prompt_builder.py` | SECONDARY | UnifiedPromptBuilder adapter | متوسطة | prompt regression | prompt tests | future approved |
| `services/prompts/prompt_builder.py` | SECONDARY | UnifiedPromptBuilder adapter | متوسطة | system prompt regression | prompt tests | future approved |
| `services/rag/prompt_builder.py` | ADAPTER | keep specialized | منخفضة | RAG context change | RAG tests | not planned |
| `hajeen_model/inference/*` | ADAPTER/COMPATIBILITY | ProviderContract/Runtime | عالية | model runtime break | runtime contract | future approved |
| direct `gpu_worker model.generate` | UNKNOWN/VIOLATION CANDIDATE | Runtime contract | عالية | bypass router/security | distributed tests | future approved |
| legacy Brain/evolution paths | LEGACY or ADAPTER | BrainV3 | عالية | hidden callers | brain/load tests | future approved |

## قاعدة

لا تُسمى legacy implementation إلا مع دليل عدم الاستخدام أو adapter واضح. حيث لا يوجد الدليل، الحالة `UNKNOWN`.


## مصادر الأدلة

- الالتزام المفحوص: `3268c262be9fb2fac9ed641d047857aa788e5566`.[1]
- الدليل الآلي: Import Graph وPhase 1/2 reports وRuntime Probes الموجودة في `docs/architecture/`.
- التصنيف المتحفظ: وجود الكود لا يساوي إثبات Runtime، ووجود اختبار وحدة لا يساوي إثبات E2E.

### References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/3268c262be9fb2fac9ed641d047857aa788e5566
