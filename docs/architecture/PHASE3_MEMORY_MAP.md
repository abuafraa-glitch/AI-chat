# Phase 3 — Memory Map

## Inventory والمقارنة

| المسار | المكونات | التصنيف | سبب القرار |
|---|---|---|---|
| `brain/memory/` | `MemoryFabric`, `UnifiedMemoryInterface` ومجالات الذاكرة | FACADE CANDIDATE | أقرب إلى Brain وتظهر كواجهة توحيد. |
| `core/memory/` | `MemoryManager`, short/long term, conversation store | SECONDARY/UNKNOWN | واجهات عملية متعددة وارتباط مباشر من core. |
| `services/memory/` | conversation/session/vector/summarization | SECONDARY/UNKNOWN | خدمات persistence متنوعة. |
| `services/memory_service.py` | `MemoryService` | ADAPTER CANDIDATE | قد يكون service boundary، لكن callers يحتاجون trace. |
| agent/self-evolution memory | agent/episodic/shared memory | SPECIALIZED | ليست بالضرورة بديل ذاكرة المحادثة. |

## قرار Phase 3

يُعتمد `brain/memory/unified_interface.py` كـ **Canonical Memory Facade candidate**، بينما implementation النهائي هو `UNKNOWN / CONSOLIDATION_REQUIRED`. السبب هو وجود نماذج بيانات وstorage وprivacy/lifecycle متعددة لم تُثبت خلف implementation واحد.

## متطلبات قبل الهجرة

يجب مقارنة serialization، persistence، tenant isolation، privacy، TTL، transaction behavior، وكل callers. لا يجوز أن يعرف Brain تفاصيل `core/memory` و`services/memory` معاً بعد مرحلة الهجرة.


## مصادر الأدلة

- الالتزام المفحوص: `3268c262be9fb2fac9ed641d047857aa788e5566`.[1]
- الدليل الآلي: Import Graph وPhase 1/2 reports وRuntime Probes الموجودة في `docs/architecture/`.
- التصنيف المتحفظ: وجود الكود لا يساوي إثبات Runtime، ووجود اختبار وحدة لا يساوي إثبات E2E.

### References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/3268c262be9fb2fac9ed641d047857aa788e5566
