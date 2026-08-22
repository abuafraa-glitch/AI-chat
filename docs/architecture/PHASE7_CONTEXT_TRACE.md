# Phase 7 — Context Trace

## العقد المتتبع

القيم الإلزامية هي `request_id` و`user_id` و`tenant_id` و`conversation_id` و`model_id`. يجب أن تبقى القيم متسقة من الهوية المصادق عليها حتى قرار التنفيذ.

```text
API
  → ChatService
  → BrainV3
  → ModelRouter
  → task envelope
  → worker admission
  → runtime/provider boundary
  → result/audit
```

| Boundary | Context requirement | Evidence | Status |
|---|---|---|---|
| API | principal وtenant مشتقان من المصادقة | `test_phase5_api_boundary.py` | TEST_PASS |
| Service | عدم قبول tenant override من client | `test_phase7_context_integrity.py` | TEST_PASS |
| Brain | model/conversation context محفوظ في العقد | context integrity tests | TEST_PASS |
| Router | model admission قبل provider | `runtime_admission.py` وsecurity tests | TEST_PASS |
| Worker envelope | القيم الخمس موجودة وغير قابلة للتبديل | worker admission tests | TEST_PASS |
| Runtime | valid context + verified model + provider admission | runtime admission tests | TEST_PASS |
| Distributed broker | نقل context عبر broker/worker منفصل | لا توجد بيئة broker تكاملية | NOT_PROVEN |
| Durable audit | حفظ الحدث بعد النتيجة | لا توجد persistence تكاملية مكتملة | NOT_PROVEN |

## Tampering cases

تم اختبار غياب `tenant_id` و`user_id` و`request_id`، وتغيير tenant أو user أو model أثناء النقل، وغياب authorization context. النتيجة المتوقعة والمتحققة في عقد admission هي الرفض المغلق، دون default tenant أو default user.

## حدود الإثبات

هذا الأثر يثبت العقد والحدود داخل الاختبارات الحالية، لكنه لا يدعي إثبات مسار موزع كامل عبر broker حقيقي أو GPU runtime.
