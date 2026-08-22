# Phase 8 — Direct Call Guardrails

تمنع اختبارات architecture الجديدة في طبقات التطبيق:

1. استيراد provider implementation مباشرة بدلاً من `ProviderRegistry`.
2. استدعاء `model.generate` من API أو service application layers.
3. تجاوز `ModelRouter` لاختيار النموذج.
4. قبول tenant identity من client input وحده.
5. تنفيذ worker بلا context envelope.
6. تشغيل Test Provider في production.
7. تمرير unknown/unverified model.

الاستثناء الوحيد هو worker/runtime، وهو استثناء موثق ومحصور خلف `security/runtime_admission.py`. الاستدعاء المباشر لا يصبح مساراً حراً؛ يلزمه context صالح وmodel verification وprovider admission.

**Status:** TEST_PASS للـguardrails المستهدفة.
