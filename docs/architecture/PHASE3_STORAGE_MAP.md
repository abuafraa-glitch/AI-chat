# Phase 3 — Storage Ownership Map

| نوع التخزين | الملكية المرشحة | الحالة | مخاطر التداخل |
|---|---|---|---|
| Relational DB | `database/` وrepository/database modules | UNKNOWN | wiring منتشر وschema غير موحد في الخريطة الحالية. |
| Object/File Storage | `storage/` وfile services | SECONDARY/UNKNOWN | قد تختلط metadata بالbytes. |
| Vector Store | `data_engine/storage/vector_store/` | CANONICAL CANDIDATE | مرتبط بالـretrieval لكن توجد wrappers. |
| Cache | `services/redis/` و`configs/redis.py` | CANONICAL DOMAIN | يحتاج تحديد key/TTL/tenant namespace. |
| Artifact Storage | model/artifact paths وexternal HF | UNKNOWN | يجب فصله عن Git وعن runtime cache. |

## قرار

لا يوجد في Phase 3 دليل كافٍ لاختيار abstraction واحد لكل storage. القرار هو `UNKNOWN / CONSOLIDATION_REQUIRED` مع إبقاء الفصل المفاهيمي بين DB وObject وVector وCache وArtifact. لا تغيير schema أو persistence.

## ضوابط الهجرة

كل adapter مستقبلي يجب أن يحدد transaction، ownership، tenant scope، serialization، retry، consistency، وbackup/restore behavior.


## مصادر الأدلة

- الالتزام المفحوص: `3268c262be9fb2fac9ed641d047857aa788e5566`.[1]
- الدليل الآلي: Import Graph وPhase 1/2 reports وRuntime Probes الموجودة في `docs/architecture/`.
- التصنيف المتحفظ: وجود الكود لا يساوي إثبات Runtime، ووجود اختبار وحدة لا يساوي إثبات E2E.

### References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/3268c262be9fb2fac9ed641d047857aa788e5566
