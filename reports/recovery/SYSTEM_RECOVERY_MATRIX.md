# Final System Recovery Matrix

| Subsystem | Exists | Implemented | Integrated | Runtime evidence | Tests | Status |
|---|---|---|---|---|---|---|
| Brain | YES | PARTIAL | PARTIAL | Focused paths only | Partial | YELLOW |
| Memory | YES | PARTIAL | PARTIAL | Persistence/focused evidence only | Partial | YELLOW |
| Model | YES | PARTIAL | YES via routing | Fail-closed; real Hajeen checkpoint unavailable | Partial | RED |
| Prompt | YES; multiple builders exist | PARTIAL authority consolidation | PARTIAL | Not end-to-end verified | Partial | YELLOW |
| Planning | YES | YES | YES in focused paths | Partial | Partial | YELLOW |
| RAG | YES | YES | YES | Focused runtime passed | 70 passed, 17 skipped | YELLOW |
| Pipeline | YES | YES | YES | Focused runtime partial | 93 passed, 3 failed | YELLOW |
| Security | YES | YES | YES | Fail-closed paths verified | 41 passed, 2 failed | YELLOW |
| API | YES | YES | YES | Focused workflow passed | 3/3 and prior 17/17 | YELLOW |
| Learning | YES | PARTIAL | PARTIAL | Checkpoint deployment deferred | Partial | RED |
| Alignment | YES | YES for orchestration | PARTIAL training runtime | No production trainer mock | Partial | YELLOW |
| Storage | YES | YES | YES | Roundtrip focused evidence | Partial | YELLOW |
| Redis | YES/configured | NOT VERIFIED | NOT VERIFIED | External resource dependent | Blocked/partial | RED |
| Celery | YES/configured | NOT VERIFIED | NOT VERIFIED | External broker/worker dependent | Partial | RED |
| Scheduler | YES/configured | NOT VERIFIED | NOT VERIFIED | Operational runtime not proven | Partial | RED |

## Decision rule

A subsystem is not GREEN merely because its modules import or because a focused test passes. Core collection blockers, missing runtime resources, failed tests, or absent real model artifacts keep the corresponding status below GREEN.
