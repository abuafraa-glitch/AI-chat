# Test Contract Issues

هذا الملف يسجل مشكلات الاختبارات التي ظهرت في baseline الحالي. لم تُحذف الاختبارات ولم تُحوّل الإخفاقات إلى skips، ولم تُغيّر assertions.

| Test group | Classification | Evidence | Root-cause hypothesis | Action in Phase 0 |
|---|---|---|---|---|
| `tests/unit/test_rss_parser.py` | BROKEN / FIXTURE-MISSING | `FileNotFoundError: tests/fixtures/sample_rss.xml` أثناء collection | Fixture مفقود من الشجرة الحالية | تسجيل فقط؛ لا اختراع fixture في Phase 0 |
| `tests/unit/test_sitemap_parser.py` | BROKEN / FIXTURE-MISSING | `FileNotFoundError: tests/fixtures/sample_sitemap.xml` أثناء collection | Fixture مفقود من الشجرة الحالية | تسجيل فقط؛ لا اختراع fixture في Phase 0 |
| `tests/unit/test_storage_phase3*.py` | LEGACY / NAMESPACE-MISMATCH | `ModuleNotFoundError: hajeen_ai_platform` | أسماء namespace قديمة مقارنة بـ`hajeen_platform` | تسجيل فقط؛ يحتاج إثبات عقد المصدر |
| `tests/unit/test_base_connector.py`, `test_cli.py`, `test_custom_connector.py`, `test_github_connector.py`, `test_ingestion_http.py`, `test_memory_unification_runtime.py`, `test_newsapi_connector.py`, `test_reddit_connector.py`, `test_requests_fetcher.py` | BROKEN / IMPORT-DEPENDENCY | Collection errors كما في `reports/phase0_levels/LEVEL_2_UNIT.log` | اعتماد أو wiring مفقود يحتاج عزل كل ملف | تسجيل فقط؛ لا mocks إنتاجية |

## Rule

لا يُعتبر هذا التقرير دليلاً على أن الاختبار خاطئ؛ التصنيف مؤقت إلى أن يُثبت العقد الصحيح من المصدر أو Git المرجعي.
