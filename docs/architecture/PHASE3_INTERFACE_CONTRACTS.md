# Phase 3 — Interface Contracts

هذه عقود توثيقية مبنية على الواجهات الحالية؛ لم تُنشأ abstractions Python جديدة.

| العقد | الواجهة الحالية | المدخلات/المخرجات | الحالة |
|---|---|---|---|
| ConversationContract | `ChatService.chat/stream` و`ChatRequest/ChatResponse` | رسالة وسياق → response أو stream | PROVEN جزئياً |
| BrainContract | `HajeenBrainV3.process/stream` | `BrainRequest` → `BrainResponse`/chunks | PROVEN عبر probes |
| MemoryContract | `UnifiedMemoryInterface` و`MemoryManager` | session/key/message → store/recall | FACADE PROVEN، backend UNKNOWN |
| RetrievalContract | `RetrievalEngine` و`SemanticRetriever` | query/top_k → hits/context | UNIT PROVEN، E2E PARTIAL |
| ModelRegistryContract | `ModelRegistry` | model identity/artifact/status → eligibility | PROVEN في الاختبارات المستهدفة |
| ModelRouterContract | `ModelRouter.route/stream/select_model` | messages/capability/budget → RouteResult/stream | PROVEN في probes |
| ProviderContract | `BaseLLMProvider` و`LLMRequest/Response` | request → response/stream | PROVEN بالعقود |
| InferenceContract | `InferenceService.generate/stream` | prompt/messages → text/chunks | CODE_EXISTS، runtime PARTIAL |
| ToolContract | schemas/registry/execution في `services/agents` و`services/tools` | validated args → result | UNKNOWN E2E |
| TenantContextContract | `multi_tenant/` وsecurity context | identity → tenant/user/resource ownership | NOT_PROVEN كاملاً |
| RelationalStorageContract | repositories/database modules | structured records → transactions | PARTIAL |
| ObjectStorageContract | storage/file modules | bytes + metadata → object ref | PARTIAL |
| VectorStorageContract | vector store managers/retrievers | vectors + metadata → hits | PARTIAL |

## قواعد العقد

يجب أن يمر الطلب المعرفي من Brain إلى ModelRouter، وأن يستشير Router الـRegistry، ثم يستخدم Provider/Runtime. لا يُسمح اعتبار `VERIFIED_BASE` دليلاً على Runtime أو inference.


## مصادر الأدلة

- الالتزام المفحوص: `3268c262be9fb2fac9ed641d047857aa788e5566`.[1]
- الدليل الآلي: Import Graph وPhase 1/2 reports وRuntime Probes الموجودة في `docs/architecture/`.
- التصنيف المتحفظ: وجود الكود لا يساوي إثبات Runtime، ووجود اختبار وحدة لا يساوي إثبات E2E.

### References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/3268c262be9fb2fac9ed641d047857aa788e5566
