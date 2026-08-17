# Phase 10 — Failure Matrix

**تاريخ القياس:** 17 أغسطس 2026  
**المبدأ:** تم تجميع الاختبارات التي تشترك في السبب الجذري نفسه، ولم تُضف mocks أو تغييرات assertions لإخفاء الإخفاقات.

## ملخص العدّ

| المصدر | Passed | Failed | Errors | Skipped | ملاحظة |
|---|---:|---:|---:|---:|---|
| Phase 9، تشغيل الملفات المنفردة | 1580 | 131 | 37 | 5 | سجل سابق موثق، لكن artifacts التفصيلية غير موجودة في الشجرة الحالية |
| Phase 10، collection الحالية | 0 | 0 | 5 | 1 | توقفت أثناء collection؛ السبب الأساسي هو غياب حزم/مسارات import |

## Root-cause groups

| ID | التصنيف | السبب الجذري | الأعراض المرصودة | النطاق | الشدة | الإجراء المطلوب | التحقق |
|---|---|---|---|---|---|---|---|
| R-GIT-01 | R | نسخة العمل الحالية لا تحتوي `.git` | تعذر `git status` و`git log` و`git branch` | كل checkpoint | حرجة | استعادة repository metadata أو العمل من clone قابل للتحقق؛ عدم الادعاء بوجود commit جديد | `git status`, `git log --oneline` |
| R-ENV-01 | R | pytest كان مفقوداً من البيئة | فشل تشغيل الاختبارات بـ `No module named pytest` | كل الاختبارات | عالية | تثبيت pytest وتسجيله في manifest عند استعادة manifest الصحيح | `python3 -m pytest --version` |
| R-IMPORT-01 | R/S | وحدات `shared` وpackage namespace `hajeen_platform` غير موجودة في الشجرة الحالية أو غير مضبوطة في PYTHONPATH | `ModuleNotFoundError: shared`, `ModuleNotFoundError: hajeen_platform` | full_pipeline، learning integration، spam detector | حرجة | استعادة الحزم من المصدر المعتمد أو تصحيح جذر الاستيراد بعد إثبات العقد | اختبارات collection وimports |
| R-ENV-02 | R | PyYAML غير مثبت | `ModuleNotFoundError: yaml` في `tests/test_api.py` | API | عالية | تسجيل وتثبيت PyYAML في manifest الرسمي | `python -c 'import yaml'` ثم test_api |
| R-CONTRACT-01 | S/Q | أسماء ملفات اختبار متكررة (`test_security.py`) مع import mode غير فريد | import file mismatch بين integration وproduction security | Security tests | متوسطة | ضبط package boundaries/import mode أو إعادة تسمية اختبار فقط إذا ثبت أنه contract test broken | collection security tests |
| A-CORE-01 | A | مسار Brain runtime غير مكتمل في النسخة السابقة | failures في `test_single_runtime_path.py` وreasoning integration | Brain/Reasoning | حرجة | تدقيق call graph الحقيقي قبل أي إصلاح؛ لا إعادة تصميم | Brain matrix + runtime tests |
| B-MEM-01 | B | عقود الذاكرة/التخزين أو العزل غير متوافقة في بعض المسارات السابقة | failures في اختبارات persistence/history/owner/session | Memory | عالية | تحديد authority واحدة لـMemoryFabric وإصلاح contract root cause | Memory unit/subsystem |
| C-MODEL-01 | C | غياب checkpoint التوليدي المحلي أو واجهة model غير مطابقة | failures في inference/final integration؛ local model RED | Model/Inference | حرجة لكن blocker منفصل | إبقاء fail-closed، لا تنزيل نموذج ولا mock production | provider/model tests |
| E-PLAN-01 | E | plan construction أو executor contract غير متسق في المسارات القديمة | failures في preparation/runtime integration | Planning/Pipeline | عالية | اختبار empty/invalid/planner/executor failure، ومنع الخطة الفارغة | planning subsystem |
| F-SEC-01 | F | عقود security أو fixtures غير متطابقة في بعض integration paths | failures في security/phase8 production tests | Security | حرجة | إصلاح السبب الحقيقي مع fail-closed وعدم استخدام skip | security unit/integration |
| G-API-01 | G/P | lifecycle أو dependency contract في health/API غير صحيح | failures في `test_health.py` و`test_api.py` السابق | API/Health | عالية | التحقق من async dependencies مثل `get_llm_manager` وإرجاع حالات واضحة | API/health tests |
| H-PIPE-01 | H | pipeline/storage/enrichment contract غير متسق | failures في `test_preparation_pipeline.py` و`test_final_integration.py` | Pipeline | عالية | تتبع Fetch→Filter→Enrich→Transform→Store مع metrics حقيقية | pipeline subsystem/integration |
| I-RAG-01 | I | اختلاف عقود RSS/Sitemap/embedding/vector persistence | failures في `test_rss_parser.py` و`test_sitemap_parser.py` ومسارات RAG | RAG/Embeddings | عالية | فصل embedding عن generative model والتحقق من persistence/reload | RAG tests |
| J-REDIS-01 | J | Redis runtime/config/failure contract غير ثابت | failures في `test_phase6_redis.py` | Redis | عالية | تشغيل Redis حقيقي إن كان مطلوباً أو توثيق optional، ثم اختبار reconnect/failure | Redis integration |
| K-CELERY-01 | K | Celery task/config/beat contract غير مكتمل | failures في `test_phase6_celery.py` | Celery | عالية | التحقق من broker/task/retry/failure بالبيئة الحقيقية | Celery integration |
| L-SCHED-01 | L | scheduler fixture أو lifecycle/shutdown contract غير صحيح | errors في `test_phase6_scheduler.py` | Scheduler | عالية | إصلاح setup/replace/get/shutdown دون mock integration | scheduler tests |
| M-DATA-01 | M | Dataset manager contract أو artifact path غير صحيح | failure في `test_dataset_manager.py` | Dataset/Learning | متوسطة | التحقق من validation/versioning/deduplication والمسارات | dataset unit |
| N-LEARN-01 | N | learning pipeline يعتمد على modules/artifacts غير مكتملة | failures في learning integration وphase7 | Learning | عالية | لا يبدأ training دون checkpoint صحيح ولا auto-deployment | learning tests |
| O-ALIGN-01 | O | إصدارات TRL/Transformers وتواقيع trainer غير متوافقة | failures السابقة في DPO/RLHF؛ تم إصلاح الجزء المركّز إلى 15/15 | Alignment | عالية | تثبيت compatibility في manifest وتشغيل trainer الحقيقي عند توفر نموذج HF حقيقي | alignment subsystem |
| Q-LEGACY-01 | Q | اختبارات قديمة تعتمد package/API/architecture سابقاً | جزء من failures المتبقية غير المصنفة تفصيلياً بعد فقدان log | Legacy | متوسطة | تصنيف ACTIVE/LEGACY/OBSOLETE/BROKEN TEST قبل تعديل production | per-test review |
| S-CONTRACT-01 | S | test contract mismatch وليس production defect | بعض الاختبارات السابقة كانت تقارن raw objects بدل enrichment | Tests | متوسطة | إصلاح الاختبار فقط عندما يثبت production behavior الصحيح | targeted test |
| R-MEM-01 | R | memory pressure في pytest الموحد | توقف عند نحو 43% دون summary | Operational | عالية | تحديد tests الثقيلة، تشغيل مجموعات، فحص caches/fixtures/model loading | reproducible grouped regression |

## نتائج Phase 10 الحالية

التشغيل الحالي بعد تثبيت pytest لم يصل إلى الاختبارات؛ توقف أثناء collection بخمسة أخطاء وحالة تخطٍ واحدة. الأخطاء الحالية ليست دليلاً على فشل Brain أو ModelRouter بحد ذاته، بل تثبت أن الشجرة الحالية ناقصة مقارنة بالمسارات التي تتوقعها الاختبارات. تحديداً، `shared` غير موجود، namespace `hajeen_platform` غير موجود كحزمة داخل الجذر الحالي، وPyYAML مفقود، كما يوجد تعارض اسم اختبار security.

## أولوية التنفيذ

يبدأ العمل من **R-IMPORT-01 وR-ENV-02** لأنهما يمنعان collection، ثم **A-CORE-01 وC-MODEL-01 وG-API-01**، ثم Memory وPlanning وSecurity وPipeline، وبعدها RAG وRedis وCelery وScheduler وLearning وAlignment، وأخيراً Legacy/obsolete tests. لا يُبدأ Redis أو Celery أو Scheduler قبل إزالة مانعات Core/collection.

## حدود الدليل

سجل Phase 9 التفصيلي `main_per_file.log` لم يعد موجوداً في مساحة العمل الحالية، لذلك لا يمكن ادعاء أسماء كل الـ131 failure والـ37 error على مستوى test name من دون إعادة تشغيل الشجرة التي أنتجتها. الأرقام والتصنيفات السابقة محفوظة باعتبارها baseline موثقاً، أما النتيجة القابلة لإعادة الإنتاج حالياً فهي collection الحالية الموضحة أعلاه.

## مراجع محلية

[1]: ../../../../phase10_current_regression.log "Phase 10 current collection log"
[2]: ../../../../phase10_root_cause_scan.txt "Phase 10 root-cause scan"
[3]: ../../../../phase10_baseline_raw.txt "Phase 10 baseline raw capture"
[4]: ../../../../phase9_final/main_per_file.log "Previous detailed regression log; unavailable in current workspace"
[5]: ../BASELINE.md "Phase 10 baseline"
