# Phase 8 — Regression Report

## Commands

```bash
python3 -m compileall -q api brain security services workers data_engine
pytest -q tests/architecture tests/integration/test_phase5_agents_tools.py tests/unit/test_phase5_ai_core.py tests/test_phase6_redis.py tests/test_phase6_scheduler.py tests/test_phase6_celery.py tests/architecture/test_phase7_*.py
```

## Result

```text
119 passed, 10 warnings in 33.34s
COMPILE_STATUS=0
TEST_STATUS=0
```

حزمة Phase 6 المستقلة بعد إصلاح عقود Celery:

```text
45 passed, 3 warnings
```

التحذيرات مرتبطة بإصدارات deprecated في pytest/Starlette/Pydantic وبعض imports القديمة، ولم تُخفَ أو تُحوّل إلى نجاح. لم يُعلن نجاح `pytest` الكامل للمستودع إذا لم يكتمل تشغيله بالكامل.

## Regression decision

**TEST_PASS** للاختبارات المستهدفة. **PARTIAL** للتكامل الموزع وpersistence الإنتاجي. **NOT_PROVEN** لـ durable audit وcross-tenant persisted resources، و**NOT_AVAILABLE** لـ Qwen runtime وRedis الإنتاجي.
