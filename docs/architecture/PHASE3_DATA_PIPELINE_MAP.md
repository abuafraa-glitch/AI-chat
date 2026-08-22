# Phase 3 — Data Pipeline Map

| المرحلة | الملكية المرشحة | مكونات ظاهرة | الحالة |
|---|---|---|---|
| Ingestion | `data_engine/ingestion/` | crawlers/connectors/fetchers | CANONICAL DOMAIN |
| Cleaning | `data_engine/processing/` | cleaning/normalization/filtering | CANONICAL DOMAIN |
| Transformation | `data_engine/processing/` | transforms/metadata | CANONICAL DOMAIN |
| Enrichment | `data_engine/processing/` وAI modules | classification/extraction | SECONDARY/UNKNOWN |
| Chunking | processing/RAG helpers | chunk builders | UNKNOWN |
| Embedding | embedding modules/workers | embedding tasks/models | UNKNOWN |
| Indexing | vector store/index stages | store/index workers | SECONDARY |
| Service boundary | `services/data_service/` | data service/conversation builder | ADAPTER CANDIDATE |
| Async execution | `workers/` | embedding/indexing tasks | CANONICAL EXECUTION DOMAIN |

## القاعدة

لا تُخلط ingestion والتنظيف والتحويل والإثراء والتقطيع والـembedding والفهرسة في service واحدة. كل مرحلة تحتاج document ID، source ID، version، status، retry/idempotency evidence.

## قرار Phase 3

`data_engine` هو المالك الأساسي للخط، و`services/data_service` boundary/adapter محتمل. لم يُثبت ownership النهائي لكل مرحلة، لذلك لا تُنقل الملفات أو تُدمج الآن.


## مصادر الأدلة

- الالتزام المفحوص: `3268c262be9fb2fac9ed641d047857aa788e5566`.[1]
- الدليل الآلي: Import Graph وPhase 1/2 reports وRuntime Probes الموجودة في `docs/architecture/`.
- التصنيف المتحفظ: وجود الكود لا يساوي إثبات Runtime، ووجود اختبار وحدة لا يساوي إثبات E2E.

### References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/3268c262be9fb2fac9ed641d047857aa788e5566
