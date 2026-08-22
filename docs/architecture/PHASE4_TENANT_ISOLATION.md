# Phase 4 — Tenant Isolation

## قاعدة الهوية

القاعدة المطلوبة هي أن تأتي هوية المستأجر من سياق مصادق عليه، لا من قيمة يرسلها العميل وحدها:

```text
Authenticated principal → tenant context → resource authorization
```

## الأدلة

| Item | Status | Finding |
|---|---|---|
| `tenant_id` vocabulary exists | CODE_EXISTS | References appear across API, security, services, and workers |
| Authenticated user context | INTEGRATED | Auth/security dependencies exist |
| Tenant context in request path | PARTIAL | Present in portions of the tree; one canonical E2E path is not proven |
| Resource ownership check | PARTIAL | Checks exist in individual services, but complete cross-tenant proof is absent |
| Tenant context in ChatService | PARTIAL | Chat and session identifiers are present; complete identity chain needs E2E |
| Tenant context in BrainV3 | NOT_PROVEN | No Phase 4 E2E trace proves propagation into every Brain call |
| Tenant context in ModelRouter | NOT_PROVEN | Router/model contracts are proven, tenant authorization integration is not |
| Tenant context in workers | PARTIAL | Task and GPU worker code accepts operational context in places; full propagation matrix is not proven |

## Required test

```text
user A + tenant A → create resource R
user B + tenant B → request R → reject
user A + tenant A → request R → allow
```

يجب أن تغطي النتيجة المحادثات والملفات ونتائج RAG والمهام الخلفية، لا المحادثات فقط.

## Status

`PARTIAL`; لا يُسمح بإعلان `PROVEN` حتى ينجح اختبار persisted-resource cross-tenant فعلياً.
