# Phase 8 — Migration Status

| Caller / area | Action | Status | Note |
|---|---|---|---|
| `brain/llm_analyzer.py` | direct SDK إلى ProviderRegistry | MIGRATED | public analyzer contract محفوظ |
| API → ChatService | canonical route inventory | PARTIAL | لا حذف للطرق القديمة |
| BrainV1/V2/legacy | inventory فقط | DEFERRED | لا دليل كافٍ على عدم وجود callers إنتاجية |
| Direct model calls | guardrails | RESTRICTED | worker/runtime exception موثق |
| Memory implementations | لا migration | DEFERRED | backend evidence غير مكتمل |
| RAG implementations | لا migration | DEFERRED | persisted tenant proof غير مكتمل |
| Prompt builders | لا حذف | DEFERRED | snapshot parity غير مكتمل |
| Storage implementations | لا migration | DEFERRED | ممنوع schema migration في هذه المرحلة |

لم تُحذف أو تُنقل أي implementation. rollback متاح عبر Git قبل الالتزام الحالي.
