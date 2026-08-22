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
