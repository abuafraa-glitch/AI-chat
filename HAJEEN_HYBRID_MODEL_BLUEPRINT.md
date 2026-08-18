# Hajeen Hybrid Model
## Architecture Definition, Backbone Selection & Build Blueprint

**الحالة:** وثيقة تأسيسية معتمدة للتدقيق والقرار والتصميم، وليست تنفيذ تدريب أو بناء نموذج.

**الفرع المستهدف:** `master`

**القيود الملزمة:** لا يبدأ Phase 9، ولا ينفذ Alignment أو Fine-tuning واسع، ولا ينشأ checkpoint إنتاجي أو Model Artifact وهمي، ولا يعدل `main`، ولا ينفذ deployment، ولا يضيف أسراراً أو مفاتيح API، ولا يستخدم fake/mock model خارج الاختبارات، ولا يغير السلطات المركزية في المنصة.

> هذه الوثيقة تميز بصرامة بين **Hajeen Platform** و**Hajeen Runtime** و**Hajeen Model** و**Hajeen Hybrid Model**. وجود BrainV3 أو RAG أو MemoryFabric أو Agents أو Tools أو ModelRouter خارجي لا يجعل النموذج نفسه هجيناً.

## 1. القرار التنفيذي

القرار المعتمد هو عدم بناء النموذج في هذه المهمة. المطلوب الحالي هو تثبيت تعريف معماري وقابلية تنفيذ يمكن استخدامها لاحقاً في دورة تدريب رسمية. لا يوجد في الحالة المدققة checkpoint حقيقي مثبت لـ Hajeen Hybrid Model، ولا يوجد artifact إنتاجي معتمد، ولا يوجد dataset إنتاجي مثبت يمكن منه حساب حجم البيانات أو عدد tokens أو composition matrix حقيقية.

الحالة الحالية هي:

| البند | Exists | Real | Verified | Production usable | الدليل الفعلي |
|---|---:|---:|---:|---:|---|
| Hajeen checkpoint حقيقي | لا | لا | لا | لا | لم توجد ملفات weights إنتاجية متتبعة مثل `*.safetensors` أو `pytorch_model.bin` |
| Hajeen Model Artifact | لا | لا | لا | لا | توجد عقود وواجهات registry، لا سجل artifact معتمد مرتبط بweights حقيقية |
| tokenizer مرتبط بـ Hajeen checkpoint | لا | لا | لا | لا | لم يوجد زوج checkpoint/tokenizer مثبت ومتحقق checksum |
| Training Run إنتاجي لـ Hajeen | لا | لا | لا | لا | توجد هياكل تدريب وcheckpoint managers، لكنها ليست دليلاً على تشغيل إنتاجي مكتمل |
| Evaluation إنتاجي لـ Hajeen | لا | لا | لا | لا | ملفات phase6 الموجودة نتائج/fixtures صغيرة وليست benchmark شامل للنموذج |
| Benchmark إنتاجي | لا | لا | لا | لا | لم يوجد benchmark manifest مستقل مع split ومنع contamination مثبت |
| Dataset إنتاجي لـ Hajeen | لا | لا | لا | لا | الموجود فعلياً يتضمن fixtures صغيرة مثل `hajeen_model/datasets/test_manager/*.jsonl` |
| DatasetVersion رسمي مكتمل | جزئي | لا | جزئي | لا | توجد `DatasetVersioner` وواجهات lifecycle، لا إصدار إنتاجي موثق بالـ checksum والمحتوى الكامل |
| ModelRegistry | نعم | نعم | نعم | نعم كسلطة | `core/model/model_registry.py` هو authority القائمة، لكنه لا يثبت وجود نموذج Hajeen بحد ذاته |
| Phase 6 lifecycle | نعم | نعم | نعم | نعم كسلطة | `brain/learning/phase6_lifecycle.py` ومسارات التقييم والتسجيل القائمة |
| Phase 7 lifecycle | نعم | نعم | نعم | نعم كسلطة | `brain/evolution/phase7_lifecycle.py` مع evidence وapproval وrollback gates |
| Hajeen internal MoE | لا | لا | لا | لا | لا توجد graph implementation تثبت MoE داخلياً داخل checkpoint Hajeen |
| Internal learned router | لا | لا | لا | لا | `brain/model_router.py` خارجي يختار provider/runtime؛ ليس router داخل النموذج |
| Platform expert layer | نعم | جزئي | نعم كطبقة منصة | لا كنموذج هجين | `brain/cognitive_layer/expert_models_layer.py` يدير خبرات/نماذج على مستوى المنصة وليس graph داخل model checkpoint |
| Dense-to-MoE conversion | لا | لا | لا | لا | لم يوجد مسار تحويل تدريبي حقيقي يثبت ذلك |

**النتيجة الصريحة:**

```text
Hajeen Model:
NOT BUILT

Hajeen Hybrid Architecture:
NOT BUILT AS A TRAINED MODEL

Hajeen Hybrid Architecture Blueprint:
DEFINED IN THIS DOCUMENT
```

وجود `hajeen_model` أو `CheckpointManager` أو أصناف `ExpertModel` لا يساوي وجود نموذج مدرب. البرهان المقبول مستقبلاً يجب أن يكون artifact قابلاً للتحميل، metadata كاملة، checksums، tokenizer متوافق، evaluation حقيقي، وModelArtifactRecord معتمد.

## 2. الحدود المعمارية

### Hajeen Platform

تتكون المنصة من BrainV3 وModelRouter وMemoryFabric وRAG وAgents وTools وAPIs وUI وServices. هذه المكونات تنسق الطلب وتوفر الذاكرة والاسترجاع والأدوات وتختار runtime أو provider.

### Hajeen Runtime

هو طبقة التحميل والتحقق والجاهزية والاستدلال للنموذج المعتمد. Phase 8 runtime مسؤول عن readiness/loading/inference contract، وليس عن اختيار الخبراء داخلياً، وليس عن تدريب النموذج، وليس عن approval أو promotion خارج ModelRegistry.

### Hajeen Model

هو checkpoint مستقل مع tokenizer وconfig وweights وmetadata يمكن تحميله وتشغيله دون BrainV3 أو RAG أو MemoryFabric أو Agents أو Tools أو external APIs.

### Hajeen Hybrid Model

هو Hajeen Model يحتوي على Hybrid Architecture داخل model graph نفسه. يجب أن يتضمن Shared Backbone وInternal Router وExperts وعمليات routing وaggregation قابلة للفحص داخل checkpoint. أما ModelRouter الخارجي فيبقى سلطة المنصة لا سلطة الخبراء داخل النموذج.

## 3. Backbone Selection

### القرار المقترح

المرشح المعماري الأفضل لهدف Hajeen Hybrid هو **Native MoE open-weight backbone**، وبالأخص Qwen3-30B-A3B كمرشح أولي مشروط بتوفر الموارد والقبول القانوني والتحقق من revision محدد. يذكر إعلان Qwen الرسمي أن Qwen3-30B-A3B نموذج MoE يحوي 30B معلمات إجمالية و3B معلمات مفعلة، وأنه تحت Apache 2.0 [1]. هذا يجعله أقرب إلى هدف Hajeen من تحويل Dense model بعد التدريب.

لا يعني هذا أن اعتماده تم. الاعتماد النهائي يتطلب تثبيت model card revision، checksum، tokenizer، config، متطلبات VRAM/RAM، compatibility مع stack الاستدلال، ونتيجة benchmark على موارد المشروع.

### مقارنة المرشحين

| المرشح | نوع البنية | الترخيص/الوضع | ملاءمة العربية والتعدد اللغوي | ملاءمة MoE | كلفة التطوير | القرار |
|---|---|---|---|---|---|---|
| Qwen3-8B | Dense | Open-weight؛ يجب تثبيت model card exact revision | قوي كخط أساس متعدد اللغات | لا يحتوي MoE داخلياً في هذا الحجم | الأقل | يعتمد كـ `Hajeen-Base-8B` وليس Hybrid |
| Qwen3-30B-A3B | Native MoE | Apache 2.0 وفق إعلان Qwen الرسمي [1]، مع التحقق من بطاقة الإصدار | مناسب للهدف مع تحقق مستقل | نعم؛ 30B total و3B active وفق المصدر الرسمي [1] | متوسطة إلى مرتفعة | المرشح الأساسي المشروط |
| Qwen3-235B-A22B | Native MoE | Apache 2.0 وفق إعلان Qwen الرسمي [1] | قوي، لكن متطلبات تشغيل وتدريب عالية جداً | نعم | مرتفعة جداً | غير مناسب للموارد الحالية دون بنية GPU كبيرة |
| Llama family | Dense أو عائلات أخرى حسب المرشح | Community/commercial license؛ ليست Apache 2.0 افتراضياً [2] | قوية، لكن شروط الترخيص تحتاج مراجعة دقيقة | تعتمد على الإصدار | متوسطة إلى مرتفعة | مرشح مقارنة لا قرار أول |
| Mistral open-weight models | Dense أو MoE حسب الإصدار | كثير من النماذج المفتوحة تستخدم Apache 2.0، لكن يجب فحص كل model card [3] | مناسبة | تعتمد على الإصدار | تتغير حسب المرشح | مرشح بديل إذا أثبتت التجارب أفضلية |

الاختيار لا يعتمد على الشهرة أو benchmark claim غير موثق. ينبغي أن يكون القرار النهائي ناتجاً عن جدول قياس يتضمن الجودة العربية، reasoning، coding، instruction following، latency، VRAM، RAM، context، training compatibility، vLLM/Transformers compatibility، وترخيص الإصدار المحدد.

### Qwen3 MoE investigation

Qwen3-30B-A3B هو نقطة البداية المنطقية لأنه Native MoE وليس Dense model يجري تجميله باسم Hybrid. عدد المعلمات الإجمالي لا يساوي كلفة كل token؛ الكلفة التشغيلية تعتمد على المعلمات النشطة، routing، batch، sequence length، quantization، وتنفيذ kernel. لذلك يجب قياس inference على hardware فعلي قبل اعتماد الخطة.

`Qwen3-235B-A22B` أقوى كمرشح نظري لكنه خارج النطاق الواقعي ما لم تتوفر بنية تدريب واستدلال كبيرة. لا أوصي به كبداية لمشروع لا يملك حالياً checkpoint أو dataset إنتاجياً مثبتاً.

## 4. Hajeen Hybrid Architecture

### البنية المقترحة

```text
Input
  │
Tokenizer
  │
Shared Transformer Embedding + Shared Attention
  │
Internal Learned Router per MoE block
  │       ├── Expert 0: Arabic / multilingual
  │       ├── Expert 1: reasoning
  │       ├── Expert 2: coding
  │       ├── Expert 3: domain knowledge
  │       └── Expert 4: instruction and safety
  │
Top-K token dispatch + capacity control
  │
Weighted expert aggregation + residual path
  │
Shared Transformer layers / output head
  │
Logits → generation
```

الاقتراح الأول هو خمسة Experts من نوع MoE FFN داخل backbone مشترك، وليس خمسة نماذج مستقلة. تبقى attention وembedding وoutput head مشتركة، بينما تستبدل طبقات FFN المختارة بخبراء متساويي البنية. هذا يقلل الكلفة مقارنة بخبراء كاملين، ويحافظ على compatibility مع Native MoE backbone.

### routing العملي

لتمثيل hidden state عند token رقم `t` بالرمز `h_t`، يحسب router logits كما يلي:

```text
r_t = W_r h_t + b_r
p_t = softmax(r_t / τ)
S_t = TopK(p_t, k=2)
```

حيث `p_t` احتمالات الخبراء، و`S_t` مجموعة الخبراء المختارين. يرسل token إلى الخبراء المختارين مع capacity factor، ثم تجمع النتائج:

```text
y_t = W_o(Σ_{e∈S_t} p_{t,e} · Expert_e(h_t)) + residual_t
```

يدخل في الخسارة:

```text
L = L_lm + λ_lb L_load_balance + λ_z L_router_z + λ_aux L_aux
```

لا يجوز تعريف routing النهائي بقواعد ثابتة مثل Arabic→A أو Coding→B. يمكن استخدام هذه القواعد كـ baseline أو labels أولية فقط. router النهائي يجب أن يكون learned، ويُقاس بتوزيع الاختيار، entropy، load skew، expert utilization، routing stability، وspecialization uplift.

### خصائص الهجين المطلوبة

| الخاصية | القرار |
|---|---|
| Shared backbone | Transformer backbone للمرشح المعتمد |
| Experts | MoE FFN experts متساوون بنيوياً ومتخصصون تدريبياً |
| العدد الأولي | خمسة، مع إمكانية تقليله بعد تحليل البيانات |
| Top-K | `k=2` كبداية قابلة للقياس |
| Router input | hidden state token-level مع context summary اختياري |
| Router output | expert probabilities ثم Top-K dispatch |
| Load balancing | auxiliary load-balance loss وcapacity factor |
| Expert collapse prevention | entropy floor، utilization gate، held-out routing checks |
| Fallback | shared path أو رفض صريح عند runtime misconfiguration؛ لا fallback خارجي صامت |
| Training | router-only ثم expert-only ثم joint optimization وفق نتائج القياس |
| Inference | model graph مستقل، دون BrainV3 أو ModelRouter خارجي |

## 5. Expert Design

لا ينبغي إضافة Expert لمجرد ملء جدول. يقترح التصميم الأولي الخبراء التاليين، لكن تثبيت العدد والتخصص يتطلب dataset audit حقيقي:

| Expert | الغرض | بيانات التدريب | routing signal | evaluation set | النجاح | الفشل |
|---|---|---|---|---|---|---|
| Arabic/Multilingual | العربية والتبديل اللغوي | بيانات عربية متعددة المجالات ومراجعة لغوية | hidden states وlanguage labels كإشراف أولي | Arabic held-out | quality وfluency وinstruction adherence | code-switch errors وhallucination |
| Reasoning | التحليل متعدد الخطوات | مسائل reasoning مع traces موثقة | task/domain labels وlearned routing | reasoning held-out | accuracy وcalibration | shortcut reasoning وlatency غير مقبول |
| Coding | الشيفرة | code مع tests وlicenses صحيحة | language/task labels أولية | executable coding benchmark | pass@k وsecurity | syntax failure وunsafe code |
| Domain | معرفة Hajeen المجال | corpus مجال مع provenance | domain labels | domain held-out | factuality وcitation discipline | stale/unsupported claims |
| Instruction/Safety | اتباع التعليمات والسلامة | instruction وsafety datasets | policy/task features | safety and refusal suite | refusal correctness وhelpfulness | jailbreak وover-refusal |

النوع الموصى به هو **MoE FFN experts** داخل Native MoE backbone. Full experts أغلى، وLoRA experts مناسبة لمرحلة استكشاف ولكنها لا تثبت بالضرورة Hybrid graph مستقل إذا بقيت خارج architecture. Adapter-only يُستخدم كـ ablation أو baseline، لا كتعريف نهائي قبل إثبات أن adapters جزء من checkpoint والgraph.

## 6. Dataset Architecture

لم يثبت التدقيق وجود Hajeen dataset إنتاجي بحجم يمكن الإبلاغ عنه. الموجود الذي ظهر في المستودع يتضمن fixtures صغيرة للاختبار مثل `hajeen_model/datasets/test_manager/data.jsonl` و`test.jsonl`، وملفات evaluation صغيرة في `storage_data/phase6/evaluation`. لا يجوز تحويل هذه الملفات إلى ادعاء عن حجم dataset أو عدد tokens.

مسار البيانات المطلوب لاحقاً هو:

```text
Raw Data
→ Cleaning
→ Deduplication
→ PII filtering
→ Safety filtering
→ Language detection
→ Quality scoring
→ Chunking
→ DatasetVersion + checksum
→ Domain classification
→ Expert/routing labels
→ Train / Validation / Test
```

### Dataset Composition Matrix الحالية

| Category | Samples | Tokens | % | Quality | Expert target |
|---|---:|---:|---:|---|---|
| General | غير متاح | غير متاح | غير قابل للحساب | غير مثبت | pending audit |
| Arabic | غير متاح | غير متاح | غير قابل للحساب | غير مثبت | Arabic/Multilingual |
| Reasoning | غير متاح | غير متاح | غير قابل للحساب | غير مثبت | Reasoning |
| Coding | غير متاح | غير متاح | غير قابل للحساب | غير مثبت | Coding |
| Domain | غير متاح | غير متاح | غير قابل للحساب | غير مثبت | Domain |
| Instruction | غير متاح | غير متاح | غير قابل للحساب | غير مثبت | Instruction/Safety |
| Preference | غير متاح | غير متاح | غير قابل للحساب | غير مثبت | later alignment |
| Safety | غير متاح | غير متاح | غير قابل للحساب | غير مثبت | Instruction/Safety |

لا يبدأ أي Training Run قبل مرور dataset عبر Phase 6 data authorities والتحقق من approval وchecksum وعدم contamination وduplicate leakage وسلامة PII والـ metadata.

## 7. Training Curriculum

لا يبدأ أي من المراحل التالية في هذه المهمة؛ هذه خطة تنفيذ لاحقة فقط.

| Stage | dataset | objective | trainable | frozen | loss | stopping/evaluation |
|---|---|---|---|---|---|---|
| 0 Base verification | official base model validation set | tokenizer/config/inference verification | لا شيء | كل النموذج | لا يوجد | stop عند failure؛ لا checkpoint إنتاجي |
| 1 Domain adaptation | approved domain corpus | domain language adaptation | adapters أو selected experts | shared backbone غالباً | causal LM | held-out perplexity/factuality |
| 2 Instruction tuning | approved instruction data | instruction following | adapters/experts ثم joint حسب الميزانية | الباقي | causal LM + formatting checks | held-out instruction suite |
| 3 Expert specialization | expert-assigned mixture | measurable specialization | experts | shared/router حسب التجربة | LM + task loss | expert-specific eval |
| 4 Router training | routing labels + unlabeled mixture | learned routing | router | experts/shared | LM + load balance + auxiliary | utilization and specialization |
| 5 Joint optimization | balanced approved mixture | end-to-end quality | experts + router وربما selected layers | optional frozen backbone | combined loss | no collapse/regression |
| 6 Preference/alignment | preference dataset | preference optimization | يقرر لاحقاً | يقرر لاحقاً | method-specific | لا ينفذ في هذه المهمة |
| 7 Safety | safety data | refusal/helpfulness | safety adapters/experts | core model | safety objectives | red-team suite |
| 8 Final evaluation | frozen held-out benchmarks | release decision | لا شيء | كل النموذج | لا يوجد | ModelRegistry approval |

### Training method decision

| Method | الفائدة | المشكلة | القرار |
|---|---|---|---|
| Full fine-tuning | أعلى حرية | موارد كبيرة وخطر catastrophic forgetting | ليس نقطة البداية |
| LoRA | منخفض التكلفة وسريع | قد لا يحقق graph hybrid مستقلاً | baseline/ablation |
| QLoRA | أقل VRAM | قد يحد من joint MoE optimization | prototype فقط إن أثبت القياس ملاءمته |
| Adapter tuning | عزل جيد | قد يبقى خارج graph المقصود | تجربة مقارنة |
| Expert-only | يثبت التخصص | router لا يتعلم بالكامل | مرحلة ضرورية |
| Router-only | يختبر routing | لا يحسن الخبراء | مرحلة قصيرة بعد تثبيت experts |
| Joint Expert+Router | يحقق الهدف النهائي | أعلى تعقيد واستقرار أصعب | الطريقة النهائية المشروطة بالموارد |

## 8. Compute Budget

هذه تقديرات تخطيطية وليست قياساً لموارد المشروع الحالية. لا يوجد في التدقيق ما يثبت توفر GPU مناسب حالياً؛ لذلك لا يُدّعى أن التدريب ممكن الآن.

| Resource | Minimal | Recommended | High |
|---|---:|---:|---:|
| GPU | 1×24 GB، prototype adapters/quantized inference | 4×80 GB، expert/router training عملي | 8–32×80 GB، joint MoE وتجارب متعددة |
| CPU RAM | 64 GB | 256 GB | 512 GB–1 TB |
| Storage | 1 TB NVMe | 4–8 TB NVMe | 20 TB+ حسب checkpoints |
| Network | 1 Gbps | 10 Gbps | 25–100 Gbps |
| Training scope | baseline/ablation | recommended expert/router curriculum | full research sweep |
| Inference | quantized small baseline | 4-bit/8-bit MoE serving | multi-GPU full precision/FP8 |
| Checkpoint storage | لا checkpoint إنتاجي في هذه المهمة | versioned staged artifacts | replicated immutable registry |

## 9. Baseline and success criteria

يجب إنشاء concept منفصل باسم `Hajeen-Base` لاحقاً، وهو Dense/derived baseline وليس Hybrid. يقاس مقابل `Hajeen Fine-tuned` ثم `Hajeen Hybrid` على نفس held-out suites وبنفس سياسة inference.

لن يُسمى النموذج Hajeen Hybrid Model إلا إذا تحققت كل الشروط التالية: وجود experts داخل graph، وجود internal learned router، تفعيل فعلي للخبراء، تخصص measurable، عدم اعتماد routing على switch خارجي hardcoded، احتواء checkpoint على architecture الهجينة، القدرة على التحميل دون Hajeen Platform، inference مستقل، قبول ModelRegistry، evaluation يثبت improvement أو specialization، وعدم الحاجة إلى external provider.

## 10. Independent Model Test

الاختبار المستقل الإلزامي لاحقاً هو:

```text
prompt
→ tokenizer
→ Hajeen Hybrid Model artifact
→ output
```

ويجب أن يعمل دون BrainV3 وRAG وMemoryFabric وAgents وTools وexternal APIs. لا يكفي نجاح API أو provider لإثبات النموذج.

بعد نجاح الاختبار المستقل فقط يختبر تكامل المنصة:

```text
User → API → BrainV3 → Platform ModelRouter → Hajeen Runtime → Hajeen Hybrid Model
```

يُمنع BrainV3 أو Agent أو Tool أو API من تحميل النموذج مباشرة. Phase 8 runtime يبقى مسؤولاً عن readiness/loading والاستدلال المعتمد فقط.

## 11. Platform Integration

تكامل النموذج مع المنصة يكون بعد اجتياز الاختبار المستقل وبعد تسجيل artifact واعتماده في ModelRegistry. لا يُسمح لـ BrainV3 أو API أو Agent أو RAG بتحميل weights أو tokenizer مباشرة. المسار الوحيد هو أن يطلب ModelRouter runtime معتمداً، وأن يتحقق runtime من readiness وartifact identity وcompatibility قبل تمرير inference.

```text
API request
→ BrainV3
→ ModelRouter
→ approved Hajeen Runtime
→ independent Hajeen Hybrid Model artifact
→ response/stream
```

يبقى RAG مسؤولاً عن retrieval وcitations، وتبقى MemoryFabric مسؤولة عن الذاكرة، وتبقى Agents مسؤولة عن orchestration والأدوات. هذه المكونات لا تدخل في تعريف Hybrid Model ولا يجوز استخدامها كدليل على وجود Internal Router. إذا كان runtime غير جاهز أو artifact غير معتمد، يجب أن يفشل المسار بوضوح ولا يتحول إلى provider أو mock غير معلن.

| طبقة | السلطة | مسؤوليتها | ما لا تفعله |
|---|---|---|---|
| BrainV3 | `brain/brain_v3.py` | orchestration وtrace وevidence | لا يحمّل weights ولا يختار expert داخلياً |
| ModelRouter | `brain/model_router.py` | اختيار runtime/provider المعتمد | لا يستبدل Internal Router |
| Hajeen Runtime | `hajeen_model/` وprovider المعتمد | readiness/loading/inference | لا يدرب ولا يوافق artifact |
| Internal Router | داخل model graph | اختيار الخبراء على مستوى token/hidden state | لا يعتمد على ModelRouter الخارجي |
| RAG | RAG authority القائمة | retrieval وcontext | لا يصبح ذاكرة أوزان أو expert |
| MemoryFabric | `brain/memory/memory_fabric.py` | telemetry وconversation memory | لا يثبت وجود checkpoint |
| ModelRegistry | `core/model/model_registry.py` | artifact approval/promotion/rollback | لا ينشئ model artifact من دون evidence |

## 12. Phase 6/7 integration

تكامل النموذج مع المنصة يكون بعد اجتياز الاختبار المستقل وبعد تسجيل artifact واعتماده في ModelRegistry. لا يُسمح لـ BrainV3 أو API أو Agent أو RAG بتحميل weights أو tokenizer مباشرة. المسار الوحيد هو أن يطلب ModelRouter runtime معتمداً، وأن يتحقق runtime من readiness وartifact identity وcompatibility قبل تمرير inference.

```text
API request
→ BrainV3
→ ModelRouter
→ approved Hajeen Runtime
→ independent Hajeen Hybrid Model artifact
→ response/stream
```

يبقى RAG مسؤولاً عن retrieval وcitations، وتبقى MemoryFabric مسؤولة عن الذاكرة، وتبقى Agents مسؤولة عن orchestration والأدوات. هذه المكونات لا تدخل في تعريف Hybrid Model ولا يجوز استخدامها كدليل على وجود Internal Router. إذا كان runtime غير جاهز أو artifact غير معتمد، يجب أن يفشل المسار بوضوح ولا يتحول إلى provider أو mock غير معلن.

| طبقة | السلطة | مسؤوليتها | ما لا تفعله |
|---|---|---|---|
| BrainV3 | `brain/brain_v3.py` | orchestration وtrace وevidence | لا يحمّل weights ولا يختار expert داخلياً |
| ModelRouter | `brain/model_router.py` | اختيار runtime/provider المعتمد | لا يستبدل Internal Router |
| Hajeen Runtime | `hajeen_model/` وprovider المعتمد | readiness/loading/inference | لا يدرب ولا يوافق artifact |
| Internal Router | داخل model graph | اختيار الخبراء على مستوى token/hidden state | لا يعتمد على ModelRouter الخارجي |
| RAG | RAG authority القائمة | retrieval وcontext | لا يصبح ذاكرة أوزان أو expert |
| MemoryFabric | `brain/memory/memory_fabric.py` | telemetry وconversation memory | لا يثبت وجود checkpoint |
| ModelRegistry | `core/model/model_registry.py` | artifact approval/promotion/rollback | لا ينشئ model artifact من دون evidence |

## 12. Decision

القرار الهندسي هو اعتماد Qwen3-30B-A3B Native MoE كمرشح أول مشروط، مع Qwen3-8B كخط أساس منفصل وليس Hybrid. السبب أن Native MoE يحقق جوهر الهدف داخل graph، بينما Fine-tuning على Dense model ينتج نموذجاً مخصصاً لا نموذجاً هجيناً. لا يعتمد القرار نهائياً قبل benchmark على الموارد الفعلية، مراجعة exact license/model-card revision، ووجود dataset معتمد.

## 13. Explicit non-deliverables

لم تُنفذ في هذه المهمة أي عملية تدريب أو Alignment أو Fine-tuning واسع أو deployment. لم يُنشأ checkpoint أو artifact أو fake model. لم تتغير `main` ولم تُضف أسرار أو مفاتيح API. لا يوجد ادعاء بأن Hajeen Model أو Hajeen Hybrid Model بُني؛ الموجود هو blueprint قابل للتنفيذ لاحقاً.

## References

[1]: https://qwenlm.github.io/blog/qwen3/ "Qwen3: Think Deeper, Act Faster"
[2]: https://ai.meta.com/blog/meta-llama-3-1/ "Introducing Llama 3.1"
[3]: https://docs.mistral.ai/models "Mistral Models Overview"
[4]: https://help.mistral.ai/en/articles/347393-under-which-license-are-mistral-s-open-models-available "Mistral open-model licensing guidance"
[5]: https://arxiv.org/abs/2505.09388 "Qwen3 Technical Report"
[6]: https://docs.nvidia.com/nemo/automodel/model-coverage/large-language-models/qwen/qwen3-moe "NVIDIA NeMo Qwen3 MoE coverage"
