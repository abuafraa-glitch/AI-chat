# Phase 11 — Restored Components

## Source

تمت الاستعادة من archive مستودع `raedthawaba/Ai` على فرع `main`، commit `ea47750b0a081c9d191995969f02a95de14d8b7b`. أثبتت مقارنة الجذر والملفات المركزية أن المصدر يحتوي على شجرة Hajeen Platform الكاملة، بينما كانت الشجرة المحلية تحتوي 81 ملفاً فقط من مكونات المشروع.

## Policy

تم نسخ الملفات المفقودة فقط. لم يتم overwrite لأي ملف كان موجوداً محلياً، ولم يتم حذف أو reset أو checkout أو pull على الشجرة الحالية. سجل العمليات الكامل موجود في `RESTORE_COPY_LOG.txt`.

## Result

| القياس | العدد |
|---|---:|
| ملفات المصدر داخل `hajeen_platform` | 831 |
| ملفات الشجرة قبل الاستعادة | 81 |
| ملفات المصدر غير الموجودة محلياً | 796 |
| الملفات المستعادة | 796 |
| الملفات الموجودة التي لم تُستبدل | 35 |

## Priority components restored

أصبحت النسخ الأصلية موجودة الآن للـ `shared` package، و`api/v1/router.py`، و`brain/memory/memory_fabric.py`، و`goal_manager.py`، و`task_decomposer.py`، و`graph_planner.py`، و`decision_engine.py`، وملفات cognitive وevidence وreflection وevolution وagents وtools، إضافة إلى اختبارات وmanifest المصدر.

## Existing files intentionally not overwritten

الملفات التي كانت موجودة محلياً، ومن بينها `brain/brain_v3.py` و`brain/model_router.py`، لم تستبدل آلياً. يلزم الآن مقارنة كل اختلاف مع commit المصدر وتحديد هل التعديل المحلي جزء من recovery سابق صالح أم اختلاف غير موثق. لا يجوز استنتاج ذلك من اسم الملف فقط.

## Evidence

`ALTERNATE_COPIES.md` يوثق hashes والأحجام والمقارنة للملفات المركزية، و`RESTORE_COPY_LOG.txt` يسجل قائمة الملفات المستعادة وقائمة الملفات التي بقيت دون overwrite.
