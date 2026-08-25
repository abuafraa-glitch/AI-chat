# سياسة بيانات Hajeen

## التعريف

كل رسالة مستخدم تدخل النظام وكل إجابة تصدر من مزود خارجي أو نموذج محلي تُعامل أولاً بوصفها **بيانات خام**. لا تُرسل رسالة المستخدم الخام إلى Policy أو Intent أو RAG أو ModelRouter، ولا تُستخدم إجابة النموذج الخام في الذاكرة أو التخزين اللاحق.

## ترتيب الإدخال

```text
user raw input
  -> InputCleaning
  -> Memory context + Policy + Intent + Goal + RAG + UnifiedPromptBuilder
  -> ModelRouter / provider
```

طبقة `InputCleaning` هي أول طبقة تنفيذية في `HajeenBrainV3.process`. تُحسب بصمة للنص الخام، وتُنتج نسخة منظفة، ثم يُستبدل `request.user_message` بالنسخة المنظفة قبل أي طبقة معرفية أو مزود نموذج.

## ترتيب الإخراج

```text
provider raw output
  -> OutputCleaning
  -> CleanConversationStore
  -> MemoryFabric
  -> API response / completed stream
```

تُحسب بصمتان مستقلتان لإجابة النموذج. تُحفظ النسخة المنظفة فقط في `cleaned_conversations` كسجل `model_output`. لا يُحفظ `raw_text`؛ البصمة وقياسات الطول واسم التحويلات هي أدلة تتبع غير قابلة لإعادة بناء النص الخام منها عملياً.

## مواقع التخزين

المسار الافتراضي هو `backend/storage_data/cleaned_conversations/YYYY/MM/DD/`. يمكن تغييره عبر `HAJEEN_CLEAN_DATA_DIR`. لكل طلب ملفان مستقلان عند نجاح المسارين: `request_id.user_message.json` و`request_id.model_output.json`.

## البث

يُجمع خرج المزود في BrainV3، وتُطبق عليه طبقة `OutputCleaning` قبل حفظه في MemoryFabric ومخزن البيانات النظيفة. تدفق القطع يحافظ على عقد `LLMStreamChunk` الحالي؛ لذلك يجب أن تعتبر السجلات النهائية (`output_cleaning` و`model_output`) مرجع إثبات الحفظ المنظف بعد اكتمال البث.
