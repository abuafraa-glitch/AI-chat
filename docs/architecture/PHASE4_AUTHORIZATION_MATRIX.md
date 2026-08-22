# Phase 4 — Authorization Matrix

## قاعدة الحالة

لا تعني `CODE_EXISTS` أو `INTEGRATED` أن العزل الأمني مثبت. لا تُستخدم `PROVEN` إلا عند وجود اختبار تنفيذي ناجح للمسار نفسه.

| Boundary | Evidence | Status | Gap / next proof |
|---|---|---|---|
| Authentication dependency | API/security modules and existing tests | INTEGRATED | Authentication E2E is NOT_PROVEN in this environment |
| Invalid token rejection | Existing auth tests / route contracts | TEST_PASS | Full deployed E2E NOT_PROVEN |
| Expired token rejection | Existing contract coverage | PARTIAL | Requires explicit expiry E2E |
| Tenant identity | `tenant_id` references in API/security/services | CODE_EXISTS | Canonical derivation and propagation require E2E |
| Wrong tenant resource | No single complete E2E proof found in Phase 4 baseline | NOT_PROVEN | Add resource-level isolation test |
| Unauthorized resource | Route/service checks exist in parts of the tree | PARTIAL | Prove against a persisted resource |
| Invalid model | ModelRouter validation and contracts | TEST_PASS | API-to-router E2E NOT_PROVEN |
| Unverified artifact | fail-closed Hajeen contract tests | TEST_PASS | Real artifact runtime NOT_AVAILABLE |
| Test provider in production | Explicit test provider is test-only in Phase 2 probes; production deployment proof absent | PARTIAL | Add production configuration rejection test |
| Malformed request | Pydantic/API validation exists | TEST_PASS | Full negative API matrix NOT_PROVEN |
| Streaming authorization | Streaming code exists in ChatService | CODE_EXISTS | WebSocket/streaming security E2E NOT_PROVEN |

## Required negative cases

```text
unauthenticated request
invalid token
expired token
wrong tenant
unauthorized resource
invalid model
unverified artifact
unavailable provider
production + test provider
malformed request
streaming authorization failure
```

## Decision

لا يوجد دليل كافٍ لإعلان Authorization `PROVEN` على مستوى المنصة كاملة. الحالة المحافظة هي `PARTIAL` مع اختبارات وحدات وعقود ناجحة، و`NOT_PROVEN` لمسارات E2E غير المنفذة.
