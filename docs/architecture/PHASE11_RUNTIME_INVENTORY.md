# PHASE 11 RUNTIME INVENTORY

## Entry points
api/__init__.py
api/dependencies.py
api/main.py
api/v1/__init__.py
api/v1/ai/__init__.py
api/v1/ai/chat.py
api/v1/ai/completion.py
api/v1/ai/embeddings.py
api/v1/ai/health.py
api/v1/ai/models.py
api/v1/ai/rerank.py
api/v1/ai/router.py
api/v1/ai/websocket.py
api/v1/auth/__init__.py
api/v1/auth/router.py
api/v1/channels/__init__.py
api/v1/channels/router.py
api/v1/embeddings/__init__.py
api/v1/embeddings/router.py
api/v1/hajeen_model_router.py
api/v1/ingestion/__init__.py
api/v1/router.py
api/v1/search/__init__.py
api/v1/search/router.py
api/v1/tasks/__init__.py
api/v1/tasks/router.py
api/v1/webhooks/__init__.py
brain/__init__.py
brain/api/__init__.py
brain/api/brain_router.py
brain/brain_v3.py
brain/cognitive_layer/__init__.py
brain/cognitive_layer/cognitive_compiler.py
brain/cognitive_layer/cognitive_constitution.py
brain/cognitive_layer/cognitive_dna.py
brain/cognitive_layer/cognitive_event_system.py
brain/cognitive_layer/cognitive_evolution_protocol.py
brain/cognitive_layer/cognitive_version_control.py
brain/cognitive_layer/concept_engine.py
brain/cognitive_layer/context_analyzer.py
brain/cognitive_layer/curiosity_engine.py
brain/cognitive_layer/decision_engine.py
brain/cognitive_layer/dream_engine.py
brain/cognitive_layer/evidence_court.py
brain/cognitive_layer/experience_memory.py
brain/cognitive_layer/experiment_engine.py
brain/cognitive_layer/expert_models_layer.py
brain/cognitive_layer/hypothesis_engine.py
brain/cognitive_layer/intent_analyzer.py
brain/cognitive_layer/knowledge_physics_engine.py
brain/cognitive_layer/meta_brain.py
brain/cognitive_layer/model_society.py
brain/cognitive_layer/planning_engine.py
brain/cognitive_layer/reasoning_engine.py
brain/cognitive_layer/test_cognitive_components.py
brain/cognitive_layer/world_model.py
brain/config.py
brain/decision_engine.py
brain/evolution/__init__.py
brain/evolution/phase7_lifecycle.py
brain/evolution/self_evolution.py
brain/evolution/test_self_evolution.py
brain/execution_trace.py
brain/goal_manager.py
brain/graph_planner.py
brain/improvement/__init__.py
brain/improvement/autonomous_improvement.py
brain/knowledge/__init__.py
brain/knowledge/knowledge_distillation.py
brain/knowledge/knowledge_graph.py
brain/learning/__init__.py
brain/learning/continuous_learning.py
brain/learning/learning_lifecycle.py
brain/learning/phase6_lifecycle.py
brain/llm_analyzer.py
brain/memory/__init__.py
brain/memory/memory_fabric.py
brain/memory/unified_interface.py
brain/metrics/__init__.py
brain/metrics/model_performance_db.py
brain/metrics_engine.py
brain/model_router.py
brain/multi_model.py
brain/policy/__init__.py
brain/policy/policy_engine.py
brain/prompts/__init__.py
brain/prompts/unified_prompt_builder.py
brain/reflection/__init__.py
brain/reflection/self_evolution.py
brain/reflection/self_reflection.py
brain/reflection/test_self_reflection.py
brain/sovereignty/__init__.py
brain/sovereignty/sovereignty_layer.py
brain/state_machine.py
brain/task_decomposer.py
brain/tests/__init__.py
brain/tests/test_brain_components.py
core/__init__.py
core/alignment/__init__.py
core/alignment/alignment_pipeline.py
core/alignment/dpo_trainer.py
core/alignment/evaluation_system.py
core/alignment/ppo_trainer.py
core/alignment/preference_dataset.py
core/alignment/reward_model.py
core/context_intelligence/context_engine.py
core/context_intelligence/context_scoring.py
core/context_intelligence/semantic_memory.py
core/distributed/gpu_scheduler.py
core/distributed/kubernetes_runtime.py
core/distributed/ray_runtime.py
core/embeddings/__init__.py
core/embeddings/base.py
core/embeddings/batch_embedder.py
core/embeddings/embedding_cache.py
core/embeddings/embedding_engine.py
core/embeddings/embedding_manager.py
core/embeddings/embedding_models.py
core/embeddings/embedding_registry.py
core/embeddings/models/__init__.py
core/embeddings/sentence_transformer.py
core/embeddings/similarity.py
core/hf_integration/__init__.py
core/hf_integration/data_cleaner.py
core/hf_integration/hub_manager.py
core/inference_engine/__init__.py
core/inference_engine/batching.py
core/inference_engine/context_manager.py
core/inference_engine/engine.py
core/inference_engine/generation.py
core/inference_engine/inference_config.py
core/inference_engine/queue_manager.py
core/inference_engine/request_handler.py
core/inference_engine/response_handler.py
core/inference_engine/response_parser.py
core/inference_engine/sampler.py
core/inference_engine/stopping.py
core/inference_engine/stream_handler.py
core/inference_engine/token_tracker.py
core/llm/__init__.py
core/llm/base.py
core/llm/config.py
core/llm/llm_manager.py
core/llm/provider_registry.py
core/llm/providers/__init__.py
core/llm/providers/hajeen_provider.py
core/llm/providers/huggingface_provider.py
core/llm/providers/llama_cpp_provider.py
core/llm/providers/mistral_finetuned_provider.py
core/llm/providers/mock_provider.py
core/llm/providers/ollama_provider.py
core/llm/providers/openai_provider.py
core/memory/__init__.py
core/memory/conversation_store.py
core/memory/long_term_memory.py
core/memory/memory_manager.py
core/memory/short_term_memory.py
core/model/__init__.py
core/model/artifact_validation.py
core/model/model_config.py
core/model/model_loader.py
core/model/model_manager.py
core/model/model_registry.py
core/model/quantization.py
core/optimization/__init__.py
core/optimization/inference_optimizer.py
core/optimization/kv_cache_manager.py
core/optimization/prompt_cache.py
core/optimization/quantization_manager.py
core/optimization/speculative_decoding.py
core/optimization/tensor_parallel.py
core/prompts/__init__.py
core/prompts/base.py
core/prompts/conversation_formatter.py
core/prompts/prompt_builder.py
core/prompts/system_prompts.py
core/prompts/templates.py
core/retrieval/__init__.py
core/retrieval/retrieval_engine.py
core/serving/__init__.py
core/serving/batching_engine.py
core/serving/llama_cpp_server.py
core/serving/load_balancer.py
core/serving/model_pool.py
core/serving/model_server.py
core/serving/request_scheduler.py
core/serving/streaming_server.py
core/serving/vllm_server.py
core/tokenizer/__init__.py
core/tokenizer/models/__init__.py
core/tokenizer/models/generic_tokenizer.py
core/tokenizer/models/llama_tokenizer.py
core/tokenizer/models/mistral_tokenizer.py
core/tokenizer/token_counter.py
core/tokenizer/tokenizer_factory.py
core/tokenizer/tokenizer_manager.py
core/training_engine/__init__.py
core/training_engine/checkpoint_manager.py
core/training_engine/collator.py
core/training_engine/dataset_loader.py
core/training_engine/evaluator.py
core/training_engine/finetuning.py
core/training_engine/lora_trainer.py
core/training_engine/metrics.py
core/training_engine/trainer.py
core/utils/__init__.py
core/utils/device_manager.py
core/utils/gpu_utils.py
core/utils/model_cache.py
orchestration/runtime/__init__.py
orchestration/runtime/dynamic_executor.py
orchestration/runtime/intelligent_router.py
orchestration/runtime/runtime_decision_system.py
services/__init__.py
services/agent_frameworks/autogen_example.py
services/agent_frameworks/custom_orchestration_runtime.py
services/agent_frameworks/langgraph_example.py
services/agent_service.py
services/agents/__init__.py
services/agents/agent_orchestrator.py
services/agents/autonomous/__init__.py
services/agents/autonomous/autonomous_agent.py
services/agents/autonomous/recursive_planner.py
services/agents/autonomous/reflection_loop.py
services/agents/autonomous/task_executor.py
services/agents/base_agent.py
services/agents/contracts.py
services/agents/execution_agent.py
services/agents/memory_agent.py
services/agents/multi_agent/collaborative_layer.py
services/agents/multi_agent/messenger.py
services/agents/multi_agent/shared_memory.py
services/agents/planner_agent.py
services/agents/retrieval_agent.py
services/agents/tool_agent.py
services/agents/tool_runtime.py
services/alignment/dpo_pipeline.py
services/alignment/rlhf_infrastructure.py
services/chat/__init__.py
services/chat/chat_service.py

## Runtime markers
api/main.py:11:  /ws/chat                           — WebSocket Chat
api/main.py:25:from fastapi import FastAPI, HTTPException, Request, WebSocket
api/main.py:68:app = FastAPI(
api/main.py:178:@app.get("/health", tags=["Health"])
api/main.py:246:@app.get("/ping", tags=["Health"])
api/main.py:253:@app.get("/api/v1/storage/stats", tags=["Storage"])
api/main.py:267:@app.post("/api/v1/index/articles", tags=["Indexing"], summary="فهرسة مقالات في Vector Store")
api/main.py:305:# ── WebSocket ─────────────────────────────────────────────────────────────
api/main.py:307:@app.websocket("/ws/chat")
api/main.py:308:async def websocket_chat(websocket: WebSocket):
api/main.py:387:        from core.llm.provider_registry import ProviderRegistry
api/main.py:388:        ProviderRegistry.auto_register_defaults()
api/main.py:393:            ProviderRegistry.register("mistral_finetuned", MistralFinetunedProvider)
api/main.py:411:    # Chat Service is now an adapter, initialized implicitly when first used via HajeenBrainV3
api/main.py:421:    # 9. تهيئة Redis Service
api/main.py:423:        from services.redis.redis_service import get_redis_service
api/main.py:424:        redis_svc = get_redis_service()
api/main.py:425:        await redis_svc.connect()
api/main.py:426:        app.state.redis = redis_svc
api/main.py:427:        logger.info("startup: Redis Service جاهز ✓")
api/main.py:429:        logger.warning("startup: فشل تهيئة Redis — %s", exc)
api/main.py:434:        if _os.getenv("DATABASE_URL", "").startswith("postgresql"):
api/main.py:449:            "startup: HajeenBrainV3 v%s جاهز ✓ (rag=%s)",
api/main.py:454:        logger.error("startup: فشل تهيئة HajeenBrainV3 — %s", exc)
api/v1/ai/chat.py:2:AI Chat Endpoints — موحّدة عبر HajeenBrainV3
api/v1/ai/chat.py:4:جميع طلبات المحادثة تمر عبر HajeenBrainV3 Pipeline الموحّد.
api/v1/ai/chat.py:7:  POST /ai/chat        → HajeenBrainV3.process() → JSON
api/v1/ai/chat.py:8:  POST /ai/chat/stream → HajeenBrainV3.stream()  → SSE
api/v1/ai/chat.py:72:            detail="HajeenBrainV3 not initialized — لا يمكن تنفيذ أي طلب خارج Brain"
api/v1/ai/chat.py:97:@router.post("/chat", response_model=ChatResponse, summary="AI Chat via Brain V3")
api/v1/ai/chat.py:100:    محادثة AI موحّدة عبر HajeenBrainV3 Pipeline الكامل.
api/v1/ai/chat.py:107:      HajeenBrainV3.process()
api/v1/ai/chat.py:111:      ModelRouter → LLM Provider
api/v1/ai/chat.py:162:            detail=f"HajeenBrainV3 processing failed: {exc}"
api/v1/ai/chat.py:189:@router.post("/chat/stream", summary="Streaming Chat via Brain V3")
api/v1/ai/chat.py:192:    محادثة متدفقة موحّدة عبر HajeenBrainV3.
api/v1/ai/chat.py:247:            error_payload = json.dumps({"event": "error", "error": str(exc), "source": "HajeenBrainV3"}, ensure_ascii=False)
api/v1/ai/completion.py:48:@router.post("/completion", response_model=CompletionResponse, summary="Text Completion عبر HajeenBrainV3")
api/v1/ai/completion.py:52:        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")
api/v1/ai/completion.py:95:@router.post("/completion/stream", summary="Streaming Text Completion عبر HajeenBrainV3")
api/v1/ai/completion.py:99:        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")
api/v1/ai/completion.py:146:            payload = {"event": "error", "error": str(e), "source": "HajeenBrainV3"}
api/v1/ai/embeddings.py:35:@router.post("/embeddings", response_model=EmbeddingResponse, summary="Generate Embeddings")
api/v1/ai/health.py:26:@router.get("/health", response_model=AIHealthResponse, summary="AI System Health")
api/v1/ai/models.py:9:from core.model.model_registry import ModelRegistry
api/v1/ai/models.py:12:_registry = ModelRegistry()
api/v1/ai/models.py:30:@router.get("/models", response_model=ModelsListResponse, summary="List Available Models")
api/v1/ai/models.py:48:@router.get("/models/{model_id}", response_model=ModelInfo, summary="Get Model Info")
api/v1/ai/rerank.py:40:@router.post("/rerank", response_model=RerankResponse, summary="Rerank Documents")
api/v1/ai/router.py:76:@router.post("/chat", summary="محادثة AI موحدة عبر HajeenBrainV3", tags=["AI"])
api/v1/ai/router.py:82:    محادثة كاملة موحدة عبر HajeenBrainV3.
api/v1/ai/router.py:86:        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")
api/v1/ai/router.py:132:@router.post("/chat/stream", summary="محادثة AI متدفقة عبر HajeenBrainV3", tags=["AI"])
api/v1/ai/router.py:138:    محادثة متدفقة موحدة عبر HajeenBrainV3.
api/v1/ai/router.py:142:        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")
api/v1/ai/router.py:205:@router.post("/rag/query", summary="RAG Query عبر HajeenBrainV3", tags=["AI", "RAG"])
api/v1/ai/router.py:211:    استعلام RAG كامل عبر HajeenBrainV3.
api/v1/ai/router.py:215:        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")
api/v1/ai/router.py:254:@router.get("/models", summary="النماذج المتاحة", tags=["AI"])
api/v1/ai/router.py:261:        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")
api/v1/ai/router.py:263:    return {"models": models, "routing_authority": "ModelRouter"}
api/v1/ai/router.py:268:@router.get("/chat/sessions/{session_id}", summary="معلومات جلسة المحادثة عبر HajeenBrainV3", tags=["AI"])
api/v1/ai/router.py:271:    الحصول على معلومات جلسة محادثة عبر HajeenBrainV3.
api/v1/ai/router.py:275:        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")
api/v1/ai/router.py:277:    # Assuming HajeenBrainV3 has a method to get session info from MemoryFabric
api/v1/ai/router.py:287:@router.post("/chat/sessions/{session_id}/clear", summary="مسح جلسة محادثة عبر HajeenBrainV3", tags=["AI"])
api/v1/ai/router.py:290:    مسح سجل جلسة محادثة عبر HajeenBrainV3.
api/v1/ai/router.py:294:        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")
api/v1/ai/router.py:296:    # Assuming HajeenBrainV3 has a method to clear session in MemoryFabric
api/v1/ai/router.py:308:@router.get("/stats", summary="إحصائيات HajeenBrainV3", tags=["AI"])
api/v1/ai/router.py:311:    إحصائيات شاملة لـ HajeenBrainV3.
api/v1/ai/router.py:315:        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")
api/v1/ai/router.py:319:@router.post("/evaluate", summary="تشغيل إطار التقييم", tags=["AI"])
api/v1/ai/websocket.py:1:"""Phase 8.5 — WebSocket Streaming: دعم WebSocket للـ streaming."""
api/v1/ai/websocket.py:9:from fastapi import WebSocket, WebSocketDisconnect
api/v1/ai/websocket.py:14:class WebSocketManager:
api/v1/ai/websocket.py:16:    إدارة اتصالات WebSocket للـ streaming.
api/v1/ai/websocket.py:20:        self._connections: Dict[str, WebSocket] = {}
api/v1/ai/websocket.py:22:    async def connect(self, websocket: WebSocket, client_id: str) -> None:
api/v1/ai/websocket.py:25:        logger.info("WebSocket connected: %s", client_id)
api/v1/ai/websocket.py:29:        logger.info("WebSocket disconnected: %s", client_id)
api/v1/ai/websocket.py:66:ws_manager = WebSocketManager()
api/v1/ai/websocket.py:69:async def handle_ws_chat(websocket: WebSocket) -> None:
api/v1/ai/websocket.py:71:    معالج WebSocket للـ chat streaming.
api/v1/ai/websocket.py:88:            except WebSocketDisconnect:
api/v1/ai/websocket.py:154:                logger.error("WebSocket streaming error: %s", e)
api/v1/ai/websocket.py:157:    except WebSocketDisconnect:
api/v1/ai/websocket.py:158:        logger.info("WebSocket client disconnected: %s", client_id)
api/v1/auth/router.py:98:@router.post("/register", summary="تسجيل مستخدم جديد", status_code=201)
api/v1/auth/router.py:126:@router.post("/login", response_model=TokenResponse, summary="تسجيل الدخول")
api/v1/auth/router.py:169:@router.post("/refresh", response_model=TokenResponse, summary="تجديد التوكن")
api/v1/auth/router.py:192:@router.post("/revoke", summary="إلغاء صلاحية التوكن")
api/v1/auth/router.py:199:@router.get("/apikeys", summary="قائمة مفاتيح API للمستخدم الحالي")
api/v1/auth/router.py:209:@router.get("/apikeys/{key_id}", summary="الحصول على تفاصيل مفتاح API")
api/v1/auth/router.py:221:@router.delete("/apikeys/{key_id}", summary="إلغاء مفتاح API")
api/v1/auth/router.py:237:@router.get("/me", summary="معلومات المستخدم الحالي")
api/v1/auth/router.py:256:@router.post("/apikeys", summary="إنشاء API Key جديد")
api/v1/auth/router.py:287:@router.get("/users", summary="قائمة المستخدمين (admin فقط)")
api/v1/channels/router.py:161:@router.post("", response_model=ChannelResponse, status_code=201)
api/v1/channels/router.py:216:@router.get("", response_model=List[ChannelResponse])
api/v1/channels/router.py:244:@router.get("/{channel_id}", response_model=ChannelResponse)
api/v1/channels/router.py:262:@router.put("/{channel_id}", response_model=ChannelResponse)
api/v1/channels/router.py:310:@router.delete("/{channel_id}", status_code=204)
api/v1/channels/router.py:323:@router.patch("/{channel_id}/pause", response_model=ChannelResponse)
api/v1/channels/router.py:342:@router.patch("/{channel_id}/resume", response_model=ChannelResponse)
api/v1/channels/router.py:361:@router.post("/{channel_id}/trigger", response_model=TriggerResponse)
api/v1/channels/router.py:472:@router.get("/{channel_id}/status", response_model=StatusResponse)
api/v1/channels/router.py:518:@router.get("/{channel_id}/audit")
api/v1/embeddings/router.py:38:@router.post("/generate", response_model=EmbedResponse, summary="توليد Embeddings")
api/v1/embeddings/router.py:70:@router.get("/models", summary="قائمة النماذج المتاحة")
api/v1/embeddings/router.py:77:@router.get("/health", summary="فحص صحة Embedding Engine")
api/v1/hajeen_model_router.py:5:- جميع طلبات AI تمر عبر HajeenBrainV3
api/v1/hajeen_model_router.py:12:  POST /api/v1/model/chat            — محادثة (موجهة عبر HajeenBrainV3)
api/v1/hajeen_model_router.py:13:  POST /api/v1/model/complete        — استدلال كامل (عبر HajeenBrainV3)
api/v1/hajeen_model_router.py:14:  POST /api/v1/model/stream          — streaming (SSE) (عبر HajeenBrainV3)
api/v1/hajeen_model_router.py:83:    """الحصول على HajeenBrainV3 من app state."""
api/v1/hajeen_model_router.py:94:@router.get("/health")
api/v1/hajeen_model_router.py:103:            "model": "Hajeen Model v1 (via HajeenBrainV3)",
api/v1/hajeen_model_router.py:113:@router.get("/info")
api/v1/hajeen_model_router.py:125:        "inference": config.get("inference", {"runtime": "HajeenBrainV3"}),
api/v1/hajeen_model_router.py:128:        "runtime": "HajeenBrainV3 (Unified Runtime)",
api/v1/hajeen_model_router.py:132:@router.post("/chat")
api/v1/hajeen_model_router.py:137:    الضمان: الطلب يمر عبر HajeenBrainV3.process() كاملاً.
api/v1/hajeen_model_router.py:167:            "runtime": "HajeenBrainV3",
api/v1/hajeen_model_router.py:171:        raise HTTPException(status_code=500, detail=f"HajeenBrainV3 error: {e}")
api/v1/hajeen_model_router.py:174:@router.post("/complete")
api/v1/hajeen_model_router.py:177:    استدلال كامل عبر HajeenBrainV3.
api/v1/hajeen_model_router.py:208:            "runtime": "HajeenBrainV3",
api/v1/hajeen_model_router.py:214:@router.post("/stream")
api/v1/hajeen_model_router.py:217:    Streaming محادثة عبر HajeenBrainV3.stream().
api/v1/hajeen_model_router.py:269:@router.get("/ollama/status")
api/v1/hajeen_model_router.py:282:@router.post("/ollama/pull")
api/v1/hajeen_model_router.py:301:@router.get("/training/status")
api/v1/hajeen_model_router.py:314:@router.post("/training/build-dataset")
api/v1/hajeen_model_router.py:330:@router.post("/training/simulate")
api/v1/hajeen_model_router.py:352:@router.post("/evaluate")
api/v1/hajeen_model_router.py:364:@router.get("/training/checkpoints")
api/v1/router.py:13:@router.get("/health", tags=["Health"])
api/v1/router.py:18:@router.get("/ping", tags=["Health"])
api/v1/search/router.py:73:@router.post("/", response_model=SearchResponseOut, summary="بحث دلالي")
api/v1/search/router.py:100:@router.post("/semantic", response_model=SearchResponseOut, summary="بحث دلالي متقدم")
api/v1/search/router.py:127:@router.post("/rag", response_model=RAGResponseOut, summary="RAG Pipeline")
api/v1/search/router.py:164:@router.get("/stats", summary="إحصائيات البحث")
api/v1/tasks/router.py:103:@router.post(
api/v1/tasks/router.py:133:@router.post(
api/v1/tasks/router.py:180:@router.get(
api/v1/tasks/router.py:221:@router.post(
api/v1/tasks/router.py:249:@router.post(
api/v1/tasks/router.py:270:@router.get(
api/v1/tasks/router.py:307:@router.post(
api/v1/tasks/router.py:329:@router.post(
api/v1/tasks/router.py:355:@router.get(
api/v1/tasks/router.py:368:@router.get(
api/v1/tasks/router.py:381:@router.get(
api/v1/tasks/router.py:400:@router.get(
brain/README.md:5:**HajeenBrainV3** هو أعلى طبقة في منصة Hajeen AI — العقل الوحيد والموحّد.  
brain/README.md:6:لا يصل أي طلب مباشرةً إلى أي نموذج لغوي — كل الطلبات تمر عبر HajeenBrainV3 أولاً.
brain/README.md:11:HajeenBrainV3 ← العقل الموحّد (Runtime واحد)
brain/README.md:56:| **HajeenBrainV3** | `brain_v3.py` | العقل الموحّد — المسار الكامل |
brain/README.md:83:| `/ai/chat` و `/brain/chat` مساران | **نفس الـ Pipeline** — عبر HajeenBrainV3 |
brain/README.md:101:كل هذه المسارات تمر بنفس الـ Pipeline عبر `HajeenBrainV3`:
brain/README.md:109:| `WS /ws/chat` | WebSocket عبر Brain V3 |
brain/__init__.py:8:    "HajeenBrainV3",
brain/__init__.py:20:            return module.HajeenBrainV3
brain/api/brain_router.py:2:Hajeen Brain API Router — واجهة REST لـ HajeenBrainV3
brain/api/brain_router.py:4:تم ترقية هذا الـ Router من Brain v2 إلى Adapter كامل لـ HajeenBrainV3.
brain/api/brain_router.py:7:- جميع الطلبات تمر عبر HajeenBrainV3.process() أو HajeenBrainV3.stream()
brain/api/brain_router.py:75:    """الحصول على HajeenBrainV3 Singleton."""
brain/api/brain_router.py:83:@router.post("/chat")
brain/api/brain_router.py:86:    المسار الكامل لـ HajeenBrainV3:
brain/api/brain_router.py:88:    → ModelRouter → LLM → MemoryFabric → Reflection → Response
brain/api/brain_router.py:117:@router.post("/stream")
brain/api/brain_router.py:119:    """محادثة متدفقة (Server-Sent Events) عبر HajeenBrainV3."""
brain/api/brain_router.py:165:@router.post("/analyze")
brain/api/brain_router.py:177:            "intent": "تحليل الطلب يتم عبر HajeenBrainV3 Pipeline",
brain/api/brain_router.py:180:                "Planning", "Decision", "ModelRouter", "MemoryFabric"
brain/api/brain_router.py:186:@router.get("/status")
brain/api/brain_router.py:188:    """حالة شاملة لـ HajeenBrainV3."""
brain/api/brain_router.py:195:            "runtime": "HajeenBrainV3",
brain/api/brain_router.py:204:            "runtime": "HajeenBrainV3",
brain/api/brain_router.py:209:@router.get("/sovereignty")
brain/api/brain_router.py:228:        "runtime": "HajeenBrainV3",
brain/api/brain_router.py:232:@router.get("/performance")
brain/api/brain_router.py:234:    """أداء النماذج عبر ModelRouter."""
brain/api/brain_router.py:239:        "runtime": "HajeenBrainV3",
brain/api/brain_router.py:243:@router.get("/memory/{session_id}")
brain/api/brain_router.py:262:@router.post("/learn")
brain/brain_v3.py:17:- HajeenBrainV3 هو Runtime الوحيد — لا يوجد مسار يتجاوزه
brain/brain_v3.py:19:- ModelRouter هو الموجه الوحيد للنماذج
brain/brain_v3.py:61:from .model_router import ModelRouter, get_model_router
brain/brain_v3.py:67:# BrainV3 itself continues to use the canonical factories above.
brain/brain_v3.py:145:    """استجابة HajeenBrainV3."""
brain/brain_v3.py:175:class HajeenBrainV3:
brain/brain_v3.py:181:      → ModelRouter → LLM → MemoryFabric → Reflection → Response
brain/brain_v3.py:195:        self.model_router: ModelRouter = get_model_router()
brain/brain_v3.py:243:            raise ValueError("EvolutionLifecycle must use BrainV3's MemoryFabric")
brain/brain_v3.py:291:        configured threshold. This keeps BrainV3 observational and non-mutating.
brain/brain_v3.py:504:            "path": "AgentOrchestrator" if use_agent else "ModelRouter",
brain/brain_v3.py:536:        # ── 9. Prompt + RAG ثم ModelRouter: المسار الرسمي للنموذج ────────
brain/brain_v3.py:623:                    raise RuntimeError(route_result.error or "ModelRouter returned an unsuccessful result")
brain/brain_v3.py:639:            logger.error("ModelRouter unavailable; failing closed: %s", exc)
brain/brain_v3.py:727:_brain_v3: Optional[HajeenBrainV3] = None
brain/brain_v3.py:730:async def get_brain_v3() -> HajeenBrainV3:
brain/brain_v3.py:731:    """الحصول على نسخة Singleton من HajeenBrainV3."""
brain/brain_v3.py:734:        _brain_v3 = HajeenBrainV3()
brain/brain_v3.py:739:async def get_brain() -> HajeenBrainV3:
brain/brain_v3.py:742:    كلاهما يعيد نفس Singleton من HajeenBrainV3.
brain/cognitive_layer/decision_engine.py:4:جزء من HajeenBrainV3 Pipeline الموحّد.
brain/cognitive_layer/decision_engine.py:86:    يستخدم ضمن HajeenBrainV3 Pipeline:
brain/cognitive_layer/expert_models_layer.py:4:جزء من HajeenBrainV3 Pipeline الموحّد.
brain/cognitive_layer/expert_models_layer.py:74:    يستخدم ضمن HajeenBrainV3 Pipeline:
brain/cognitive_layer/planning_engine.py:4:جزء من HajeenBrainV3 Pipeline الموحّد.
brain/cognitive_layer/planning_engine.py:83:    يستخدم ضمن HajeenBrainV3 Pipeline:
brain/cognitive_layer/reasoning_engine.py:4:جزء من HajeenBrainV3 Pipeline الموحّد.
brain/cognitive_layer/reasoning_engine.py:62:    يستخدم ضمن HajeenBrainV3 Pipeline:
brain/decision_engine.py:155:        # opts in; ordinary requests remain on the direct BrainV3->ModelRouter path.
brain/decision_engine.py:365:    BrainV3 is constructed synchronously, while worker/reflection callers may
brain/learning/continuous_learning.py:708:            "legacy deployment blocked: use LearningLifecycleCoordinator and ModelRegistry"
brain/learning/learning_lifecycle.py:7:from core.model.model_registry import ModelArtifactRecord, ModelArtifactStatus, ModelRegistry
brain/learning/learning_lifecycle.py:36:        registry: Optional[ModelRegistry] = None,
brain/learning/learning_lifecycle.py:41:        self.registry = registry or ModelRegistry()
brain/llm_analyzer.py:11:from core.llm.provider_registry import ProviderRegistry
brain/llm_analyzer.py:51:    """Analyze a request through ProviderRegistry; no provider SDK bypass."""
brain/llm_analyzer.py:57:    ProviderRegistry.auto_register_defaults()
brain/llm_analyzer.py:58:    provider = ProviderRegistry.create(
brain/model_router.py:12:from core.llm.provider_registry import ProviderRegistry
brain/model_router.py:13:from core.model.model_registry import ModelArtifactStatus, ModelRegistry
brain/model_router.py:86:class ModelRouter:
brain/model_router.py:89:    def __init__(self, prefer_local: bool = True, model_registry: Optional[ModelRegistry] = None) -> None:
brain/model_router.py:91:        self._model_registry = model_registry or ModelRegistry()
brain/model_router.py:110:    def set_model_registry(self, registry: ModelRegistry) -> None:
brain/model_router.py:173:            ProviderRegistry.auto_register_defaults()
brain/model_router.py:177:            provider_cls = ProviderRegistry.get(adapter_name)
brain/model_router.py:351:_router: Optional[ModelRouter] = None
brain/model_router.py:354:def get_model_router() -> ModelRouter:
brain/model_router.py:357:        _router = ModelRouter()
brain/model_router.py:361:def set_model_router(router: ModelRouter) -> None:
brain/model_router.py:366:__all__ = ["ModelConfig", "RouteResult", "ModelRouter", "get_model_router", "set_model_router"]
brain/prompts/unified_prompt_builder.py:24:  ModelRouter → LLM
brain/reflection/self_reflection.py:30:from ..model_router import ModelRouter, get_model_router
brain/reflection/self_reflection.py:100:        self._model_router: Optional[ModelRouter] = None
core/llm/__init__.py:3:from .provider_registry import ProviderRegistry
core/llm/__init__.py:13:    "ProviderRegistry",
core/llm/llm_manager.py:18:from .provider_registry import ProviderRegistry
core/llm/llm_manager.py:46:        # Compatibility facade: ModelRouter remains the sole selection authority.
core/llm/llm_manager.py:47:        from brain.model_router import ModelRouter
core/llm/llm_manager.py:48:        self._router = ModelRouter(prefer_local=self.settings.provider in {"local", "hajeen"})
core/llm/llm_manager.py:55:        ProviderRegistry.auto_register_defaults()
core/llm/llm_manager.py:79:            provider = ProviderRegistry.create(name, config)
core/llm/llm_manager.py:134:            raise LLMError(result.error or "ModelRouter returned an unsuccessful result")
core/llm/provider_registry.py:17:class ProviderRegistry:
core/llm/provider_registry.py:80:__all__ = ["ProviderRegistry"]
core/llm/providers/hajeen_provider.py:1:"""Hajeen Model adapter used by the Platform ModelRouter."""
core/model/model_registry.py:55:class ModelRegistry:
core/model/model_registry.py:58:    _instance: Optional["ModelRegistry"] = None
core/model/model_registry.py:61:    def __new__(cls) -> "ModelRegistry":
core/model/model_registry.py:75:        logger.info("ModelRegistry initialized with %d defaults", len(self._configs))
core/optimization/prompt_cache.py:14:import redis
core/optimization/prompt_cache.py:35:        redis_client: redis.Redis,
core/optimization/prompt_cache.py:39:        self.redis = redis_client
core/optimization/prompt_cache.py:68:        self.redis.setex(f"prompt_cache:meta:{prefix_hash}", self.ttl, json.dumps(meta))
core/optimization/prompt_cache.py:84:        meta_raw = self.redis.get(f"prompt_cache:meta:{prefix_hash}")
core/optimization/prompt_cache.py:104:        self.redis.delete(f"prompt_cache:meta:{prefix_hash}")
core/serving/model_server.py:76:app = FastAPI(
core/serving/model_server.py:111:@app.get("/health")
core/serving/model_server.py:123:@app.get("/ready")
core/serving/model_server.py:130:@app.post("/generate", response_model=GenerationResponse)
core/serving/model_server.py:168:@app.get("/models")
core/serving/model_server.py:175:@app.post("/models/{model_name}/load")
core/serving/model_server.py:183:@app.post("/models/{model_name}/unload")
core/serving/model_server.py:191:@app.get("/metrics")
services/agents/agent_orchestrator.py:38:    authorities owned by BrainV3/platform services.
services/agents/planner_agent.py:36:            raise RuntimeError("Canonical planner requires ModelRouter and UnifiedPromptBuilder")
services/chat/__init__.py:2:from .chat_service import ChatService, ChatRequest, ChatResponse
services/chat/__init__.py:9:    "ChatService", "ChatRequest", "ChatResponse",
services/chat/chat_service.py:2:ChatService (Adapter) — خدمة الدردشة الرئيسية
services/chat/chat_service.py:16:from brain.brain_v3 import BrainRequest, BrainResponse, HajeenBrainV3, get_brain_v3
services/chat/chat_service.py:70:class ChatService:
services/chat/chat_service.py:78:        brain: Optional[HajeenBrainV3] = None,
services/chat/chat_service.py:99:        logger.info("ChatService initialized with UnifiedMemoryInterface (SSOT Mode)")
services/chat/chat_service.py:102:        """تنفيذ محادثة كاملة عبر HajeenBrainV3."""
services/chat/chat_service.py:189:        """محادثة مع native streaming عبر HajeenBrainV3."""
services/chat/chat_service.py:274:_chat_service: Optional[ChatService] = None
services/chat/chat_service.py:276:def get_chat_service() -> ChatService:
services/chat/chat_service.py:279:        _chat_service = ChatService()
services/distributed_messaging/celery_config.py:7:celery_app = Celery(
services/distributed_messaging/celery_config.py:9:    broker=os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/0"),
services/distributed_messaging/celery_config.py:10:    backend=os.getenv("CELERY_BACKEND_URL", "redis://localhost:6379/1"),
services/distributed_messaging/redis_streams_integration.py:1:import redis
services/distributed_messaging/redis_streams_integration.py:8:class RedisStreamsClient:
services/distributed_messaging/redis_streams_integration.py:10:        self.redis_client = redis.Redis(host=host, port=port, db=db, decode_responses=True)
services/distributed_messaging/redis_streams_integration.py:11:        logger.info(f"RedisStreamsClient initialized for {host}:{port}/{db}")
services/distributed_messaging/redis_streams_integration.py:14:        """Adds a message to a Redis Stream."""
services/distributed_messaging/redis_streams_integration.py:16:            message_id = self.redis_client.xadd(stream_name, message_data)
services/distributed_messaging/redis_streams_integration.py:20:            logger.error(f"Error adding message to Redis Stream \'{stream_name}\': {e}")
services/distributed_messaging/redis_streams_integration.py:24:        """Reads messages from a Redis Stream using a consumer group."""
services/distributed_messaging/redis_streams_integration.py:28:                self.redis_client.xgroup_create(stream_name, consumer_group, id=">", mkstream=True)
services/distributed_messaging/redis_streams_integration.py:29:            except redis.exceptions.ResponseError as e:
services/distributed_messaging/redis_streams_integration.py:33:            messages = self.redis_client.xreadgroup(
services/distributed_messaging/redis_streams_integration.py:42:                    self.redis_client.xack(stream_name, consumer_group, msg_id)
services/distributed_messaging/redis_streams_integration.py:47:            logger.error(f"Error reading messages from Redis Stream \'{stream_name}\': {e}")
services/distributed_messaging/redis_streams_integration.py:50:print("Redis Streams integration example created.")
services/memory/session_manager.py:50:        """متوافق مع ChatService القديم."""
services/redis/__init__.py:1:from services.redis.redis_service import RedisService, get_redis_service
services/redis/__init__.py:3:__all__ = ["RedisService", "get_redis_service"]
services/redis/redis_service.py:1:"""Redis Full Integration Service — Cache + Sessions + Queue + Streaming.
services/redis/redis_service.py:18:import redis.asyncio as aioredis
services/redis/redis_service.py:22:REDIS_URL     = os.getenv("REDIS_URL", "redis://localhost:6379/0")
services/redis/redis_service.py:23:REDIS_CACHE   = os.getenv("REDIS_CACHE_URL", "redis://localhost:6379/1")
services/redis/redis_service.py:24:REDIS_QUEUE   = os.getenv("REDIS_QUEUE_URL", "redis://localhost:6379/2")
services/redis/redis_service.py:37:class RedisService:
services/redis/redis_service.py:38:    """خدمة Redis موحّدة — 3 قواعد بيانات منفصلة."""
services/redis/redis_service.py:41:        self._main: Optional[aioredis.Redis] = None
services/redis/redis_service.py:42:        self._cache: Optional[aioredis.Redis] = None
services/redis/redis_service.py:43:        self._queue: Optional[aioredis.Redis] = None
services/redis/redis_service.py:48:            self._main  = await aioredis.from_url(REDIS_URL,  encoding="utf-8", decode_responses=True)
services/redis/redis_service.py:49:            self._cache = await aioredis.from_url(REDIS_CACHE, encoding="utf-8", decode_responses=True)
services/redis/redis_service.py:50:            self._queue = await aioredis.from_url(REDIS_QUEUE, encoding="utf-8", decode_responses=True)
services/redis/redis_service.py:53:            logger.info("Redis connected: main=%s cache=%s queue=%s", REDIS_URL, REDIS_CACHE, REDIS_QUEUE)
services/redis/redis_service.py:55:            logger.warning("Redis connection failed: %s — running without cache", e)
services/redis/redis_service.py:189:                "version": info.get("redis_version"),
services/redis/redis_service.py:199:_redis_service: Optional[RedisService] = None
services/redis/redis_service.py:202:def get_redis_service() -> RedisService:
services/redis/redis_service.py:203:    global _redis_service
services/redis/redis_service.py:204:    if _redis_service is None:
services/redis/redis_service.py:205:        _redis_service = RedisService()
services/redis/redis_service.py:206:    return _redis_service
workers/async_tasks.py:92:        "through BrainV3/EvolutionLifecycle."
workers/celery_app.py:8:- memory broker (بدون Redis) للتطوير المحلي
workers/celery_app.py:41:app = Celery("hajeen_workers")
workers/celery_config.py:1:"""Celery Configuration — يدعم وضع in-memory بدون Redis لتطوير محلي.
workers/celery_config.py:3:للتشغيل بدون Redis:
workers/celery_config.py:7:للتشغيل مع Redis:
workers/celery_config.py:8:    export REDIS_URL=redis://localhost:6379/0
workers/celery_config.py:18:REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
workers/celery_config.py:20:# الوضع الافتراضي: in-memory إذا لم يكن Redis متاحاً
workers/celery_config.py:24:    # in-memory broker للتطوير المحلي بدون Redis
workers/distributed/queue_router.py:13:import redis
workers/distributed/queue_router.py:89:    def __init__(self, redis_client: redis.Redis, celery_app: Celery) -> None:
workers/distributed/queue_router.py:90:        self.redis = redis_client
workers/distributed/queue_router.py:133:        cached = self.redis.get(cache_key)
workers/distributed/queue_router.py:155:            self.redis.setex(cache_key, 10, str(load))
workers/distributed/queue_router.py:170:            depth = self.redis.llen(key)
workers/distributed/queue_router.py:198:        self.redis.lpush("dead_letter_queue", str(payload))
workers/distributed/scheduler_manager.py:12:import redis
workers/distributed/scheduler_manager.py:91:    def __init__(self, celery_app: Celery, redis_client: redis.Redis) -> None:
workers/distributed/scheduler_manager.py:93:        self.redis = redis_client
workers/distributed/scheduler_manager.py:127:        self.redis.set(key, "1")
workers/distributed/scheduler_manager.py:135:        self.redis.delete(f"scheduler:disabled:{task_name}")
workers/distributed/scheduler_manager.py:144:            last_run = self.redis.get(last_run_key)
workers/distributed/scheduler_manager.py:158:    redis_url = os.environ.get("REDIS_URL", "redis://localhost:6379/0")
workers/distributed/scheduler_manager.py:159:    r = redis.from_url(redis_url, socket_connect_timeout=2)
workers/distributed/worker_monitor.py:13:import redis
workers/distributed/worker_monitor.py:39:    def __init__(self, redis_client: redis.Redis, celery_app: Any) -> None:
workers/distributed/worker_monitor.py:40:        self.redis = redis_client
workers/distributed/worker_monitor.py:56:                heartbeat = self.redis.get(hb_key)
workers/distributed/worker_monitor.py:86:        self.redis.setex(key, int(self.HEARTBEAT_TIMEOUT * 2), str(time.time()))
workers/distributed/worker_monitor.py:90:        keys = self.redis.keys(f"{self.HEARTBEAT_KEY_PREFIX}*")
workers/distributed/worker_monitor.py:92:            raw = self.redis.get(key)
workers/distributed/worker_monitor.py:103:            length = self.redis.llen(f"celery:{queue}")

## Dependency manifests
--- requirements.txt
# ══════════════════════════════════════════════════════════════════════
# Hajeen Platform — Requirements
# ══════════════════════════════════════════════════════════════════════

# ── HuggingFace Ecosystem ─────────────────────────────────────────────
huggingface_hub>=0.23.0
datasets>=2.20.0
transformers>=4.41.0
tokenizers>=0.19.0
accelerate>=0.31.0
safetensors>=0.4.3
sentencepiece>=0.2.0
peft>=0.11.0

# ── Environment ──────────────────────────────────────────────────────
python-dotenv>=1.0.1

# ── Deep Learning ────────────────────────────────────────────────────
torch>=2.3.0
torchvision>=0.18.0

# ── API Framework ────────────────────────────────────────────────────
fastapi>=0.111.0
uvicorn[standard]>=0.30.0
pydantic>=2.7.0
httpx>=0.27.0

# ── Data Processing ──────────────────────────────────────────────────
numpy>=1.26.0
pandas>=2.2.0
scipy>=1.13.0

# ── Text Processing ──────────────────────────────────────────────────
regex>=2024.5.15
langdetect>=1.0.9
beautifulsoup4>=4.12.3
lxml>=5.2.0

# ── Storage ──────────────────────────────────────────────────────────
chromadb>=0.5.0
faiss-cpu>=1.8.0
qdrant-client>=1.9.0

# ── Task Queue ───────────────────────────────────────────────────────
celery>=5.4.0
redis>=5.0.0
apscheduler>=3.10.4

# ── Embeddings ───────────────────────────────────────────────────────
sentence-transformers>=3.0.0

# ── Database ─────────────────────────────────────────────────────────
sqlalchemy>=2.0.30
aiosqlite>=0.20.0

# ── Web Crawling ─────────────────────────────────────────────────────
requests>=2.32.0
urllib3>=2.2.0

# ── Monitoring & Logging ─────────────────────────────────────────────
structlog>=24.1.0
prometheus-client>=0.20.0

# ── Testing ──────────────────────────────────────────────────────────
pytest>=8.2.0
pytest-asyncio>=0.23.0
respx>=0.23.0
fakeredis>=2.23.0

# ── YAML & Config ────────────────────────────────────────────────────
pyyaml>=6.0.1

aiobreaker>=1.2.0
feedparser>=6.0.11
tenacity>=8.2.3
datasketch>=1.6.5
--- requirements-prod.txt
# ── Production-only dependencies ─────────────────────────────────────────────
asyncpg>=0.29.0
sqlalchemy[asyncio]>=2.0.30
alembic>=1.13.0
redis[asyncio]>=5.0.0
uvloop>=0.19.0
httptools>=0.6.0
PyJWT>=2.8.0
bcrypt>=4.1.0
prometheus-fastapi-instrumentator>=7.0.0
opentelemetry-sdk>=1.24.0
opentelemetry-instrumentation-fastapi>=0.45b0
peft>=0.11.0
trl>=0.9.0
bitsandbytes>=0.43.0
--- pyproject.toml
[tool.black]
line-length = 88
target-version = ['py311']
include = '\.pyi?$'

[tool.ruff]
line-length = 88
target-version = "py311"
select = ["E", "F", "I"]
fix = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = "test_*.py"
pythonpath = ["."]
addopts = "-v"
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "function"

[tool.mypy]
python_version = "3.11"
strict = true
ignore_missing_imports = true
--- configs/redis.py
"""Redis Infrastructure — section 6.1.

Provides a unified Redis connection manager with:
- Async and sync connection pools
- Health checks
- Retry connection logic with exponential backoff
- Fail-closed behavior when Redis is unavailable
"""
from __future__ import annotations

import asyncio
import logging
import os
import time
from dataclasses import dataclass, field
from typing import Any, Optional

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

@dataclass
class RedisConfig:
    """Redis connection settings."""

    host: str = field(default_factory=lambda: os.getenv("REDIS_HOST", "localhost"))
    port: int = field(default_factory=lambda: int(os.getenv("REDIS_PORT", "6379")))
    db: int = field(default_factory=lambda: int(os.getenv("REDIS_DB", "0")))
    password: Optional[str] = field(default_factory=lambda: os.getenv("REDIS_PASSWORD"))
    max_connections: int = 20
    socket_timeout: float = 5.0
    socket_connect_timeout: float = 3.0
    retry_on_timeout: bool = True
    retry_max_attempts: int = 3
    retry_delay: float = 1.0         # initial delay in seconds
    retry_backoff_factor: float = 2.0

    @property
    def url(self) -> str:
        """Build a redis:// URL from settings."""
        auth = f":{self.password}@" if self.password else ""
        return f"redis://{auth}{self.host}:{self.port}/{self.db}"

    @classmethod
    def from_env(cls) -> "RedisConfig":
        """Create config from environment variables."""
        url = os.getenv("REDIS_URL", "")
        if url:
            # Parse redis://[:password@]host[:port][/db]
            try:
                from urllib.parse import urlparse
                parsed = urlparse(url)
                return cls(
                    host=parsed.hostname or "localhost",
                    port=parsed.port or 6379,
                    db=int(parsed.path.lstrip("/") or 0),
                    password=parsed.password,
                )
            except Exception:
                pass
        return cls()


# ---------------------------------------------------------------------------
# Redis Manager
# ---------------------------------------------------------------------------

class RedisManager:
    """Async-capable Redis connection manager.

    Fails closed when the real Redis server is unavailable; no in-memory
    substitute is used in the production path.

    Parameters
    ----------
    config:
        :class:`RedisConfig` — defaults to loading from environment.
    """

    def __init__(self, config: Optional[RedisConfig] = None) -> None:
        self.config = config or RedisConfig.from_env()
        self._client: Any = None
        self._async_client: Any = None

    # ------------------------------------------------------------------
    # Connection lifecycle
    # ------------------------------------------------------------------

    def connect(self) -> None:
        """Open a synchronous Redis connection."""
        if self._client is not None:
            return
        self._client = self._connect_with_retry()

    async def async_connect(self) -> None:
        """Open an asynchronous Redis connection."""
        if self._async_client is not None:
            return
        self._async_client = await self._async_connect_with_retry()

    def disconnect(self) -> None:
        """Close the synchronous connection."""
        if self._client:
            try:
                self._client.close()
            except Exception:
                pass
        self._client = None

    async def async_disconnect(self) -> None:
        """Close the asynchronous connection."""
        if self._async_client:
            try:
                await self._async_client.aclose()
            except Exception:
                pass
        self._async_client = None

    # ------------------------------------------------------------------
    # Health checks
    # ------------------------------------------------------------------

    def ping(self) -> bool:
        """Return True if the synchronous connection is alive."""
        try:
            if self._client is None:
                self.connect()
            return self._client.ping()
        except Exception as exc:
            logger.warning("RedisManager.ping failed: %s", exc)
            return False

    async def async_ping(self) -> bool:
        """Return True if the asynchronous connection is alive."""
        try:
            if self._async_client is None:
                await self.async_connect()
            return await self._async_client.ping()
        except Exception as exc:
            logger.warning("RedisManager.async_ping failed: %s", exc)
            return False

    def health_check(self) -> dict:
        """Return a health report dict."""
        try:
            alive = self.ping()
            info = {}
            if alive and self._client:
                raw = self._client.info("server")
                info = {
                    "version": raw.get("redis_version", "?"),
                    "uptime_seconds": raw.get("uptime_in_seconds", 0),
                    "used_memory_human": raw.get("used_memory_human", "?"),
                }
            return {
                "status": "ok" if alive else "error",
                "backend": "redis",
                "host": self.config.host,
                "port": self.config.port,
                "db": self.config.db,
                **info,
            }
        except Exception as exc:
            return {"status": "error", "error": str(exc)}

    # ------------------------------------------------------------------
    # Client accessors
    # ------------------------------------------------------------------

    @property
    def client(self):
        """Synchronous Redis client (auto-connects)."""
        if self._client is None:
            self.connect()
        return self._client

    @property
    def async_client(self):
        """Async Redis client — must call ``async_connect`` first."""
        return self._async_client

    # ------------------------------------------------------------------
    # Context managers
    # ------------------------------------------------------------------

    def __enter__(self) -> "RedisManager":
        self.connect()
        return self

    def __exit__(self, *_: object) -> None:
        self.disconnect()

    async def __aenter__(self) -> "RedisManager":
        await self.async_connect()
        return self

    async def __aexit__(self, *_: object) -> None:
        await self.async_disconnect()

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _connect_with_retry(self):
        """Attempt Redis connection with exponential backoff."""
        cfg = self.config
        delay = cfg.retry_delay

        for attempt in range(1, cfg.retry_max_attempts + 1):
            try:
                return self._make_sync_client()
            except Exception as exc:
                logger.warning(
                    "Redis sync connect attempt %d/%d failed: %s",
                    attempt, cfg.retry_max_attempts, exc,
                )
                if attempt < cfg.retry_max_attempts:
                    time.sleep(delay)
--- shared/database.py
import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

# Use SQLite for local development
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./hajeen.sqlite3")

engine = create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
--- services/distributed_messaging/celery_config.py
import os
import time

from celery import Celery

# Configure Celery
celery_app = Celery(
    "hajeen_tasks",
    broker=os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/0"),
    backend=os.getenv("CELERY_BACKEND_URL", "redis://localhost:6379/1"),
    include=["services.distributed_messaging.tasks"],
)

celery_app.conf.update(
    task_acks_late=True,
    task_reject_on_worker_lost=True,
    worker_prefetch_multiplier=1,
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    timezone="UTC",
    enable_utc=True,
)

# Example task (would be in services.distributed_messaging.tasks)
@celery_app.task
def process_data(data: dict) -> dict:
    print(f"Processing data: {data}")
    # Simulate some work
    time.sleep(2)
    return {"status": "processed", "original_data": data, "processed_at": time.time()}

print("Celery configuration example created.")
--- workers/celery_app.py
"""Celery Application — section 6.2.

Single Celery app instance. Imports settings from celery_config.py
and auto-discovers tasks in workers/tasks/.

يدعم:
- graceful shutdown مع حفظ الحالة
- memory broker (بدون Redis) للتطوير المحلي
- signal handlers آمنة
- lifecycle hooks شاملة
"""
from __future__ import annotations

import logging
import os
import signal
import sys

from celery import Celery
from celery.signals import (
    task_failure,
    task_postrun,
    task_prerun,
    task_retry,
    worker_ready,
    worker_shutdown,
    worker_process_init,
)
from dotenv import load_dotenv

load_dotenv()

from workers import celery_config  # noqa: E402

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# App instance
# ---------------------------------------------------------------------------

app = Celery("hajeen_workers")
app.config_from_object(celery_config, namespace="")

# Auto-discover tasks
app.autodiscover_tasks(["workers.tasks"])

# ---------------------------------------------------------------------------
# Worker lifecycle signals
# ---------------------------------------------------------------------------

@worker_process_init.connect
def on_worker_process_init(**kwargs):  # type: ignore[no-untyped-def]
    """تهيئة worker process — إعداد logging وإعدادات عامة."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )
    logger.info("Hajeen worker process initialized — PID=%d", os.getpid())


@worker_ready.connect
def on_worker_ready(sender, **kwargs):  # type: ignore[no-untyped-def]
    queues = list(getattr(celery_config, "TASK_QUEUES", {}).keys())
    logger.info(
        "Hajeen worker ready — PID=%d queues=[%s]",
        os.getpid(),
        ", ".join(queues),
    )


@worker_shutdown.connect
def on_worker_shutdown(sender, **kwargs):  # type: ignore[no-untyped-def]
    """Graceful shutdown — حفظ الحالة وإغلاق الموارد."""
    logger.info("Hajeen worker shutting down gracefully — PID=%d", os.getpid())
    try:
        # إغلاق StorageManager إذا كان متصلاً
        import asyncio
        from data_engine.storage.storage_manager import get_storage_manager
        sm = get_storage_manager()
        if sm._connected:
            loop = asyncio.new_event_loop()
            loop.run_until_complete(sm.disconnect())
            loop.close()
            logger.info("worker_shutdown: StorageManager أُغلق بأمان")
    except Exception as exc:
        logger.warning("worker_shutdown: تعذّر إغلاق StorageManager — %s", exc)

    logger.info("Hajeen worker shutdown complete ✓")


# ---------------------------------------------------------------------------
# Task lifecycle signals
# ---------------------------------------------------------------------------

@task_prerun.connect
def on_task_prerun(task_id, task, args, kwargs, **extras):  # type: ignore[no-untyped-def]
    logger.info(
        "TASK_START id=%s name=%s",
        task_id,
        task.name,
    )


@task_postrun.connect
def on_task_postrun(task_id, task, retval, state, **extras):  # type: ignore[no-untyped-def]
    logger.info(
        "TASK_DONE  id=%s name=%s state=%s",
        task_id,
        task.name,
        state,
    )


@task_retry.connect
def on_task_retry(request, reason, einfo, **extras):  # type: ignore[no-untyped-def]
    logger.warning(
        "TASK_RETRY id=%s name=%s reason=%s retries=%d",
        request.id,
        request.task,
        reason,
        request.retries,
    )


@task_failure.connect
def on_task_failure(task_id, exception, traceback, sender, **extras):  # type: ignore[no-untyped-def]
    logger.error(
        "TASK_FAIL  id=%s name=%s error=%s",
        task_id,
        sender.name,
        exception,
    )
    # Dead-letter: تسجيل المهام الفاشلة في ملف
    try:
        import json
        from pathlib import Path
        dl_path = Path("logs/dead_letter_tasks.jsonl")
        dl_path.parent.mkdir(parents=True, exist_ok=True)
        import time
        record = {
            "task_id": task_id,
            "task_name": sender.name,
            "error": str(exception),
            "timestamp": time.time(),
        }
        with open(dl_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
    except Exception as exc:
        logger.warning("dead_letter write error: %s", exc)


# ---------------------------------------------------------------------------
# Graceful shutdown signal handlers
# ---------------------------------------------------------------------------

def _graceful_shutdown(signum, frame):
    """إغلاق آمن عند SIGTERM / SIGINT."""
    sig_name = signal.Signals(signum).name if hasattr(signal, "Signals") else str(signum)
    logger.info("Hajeen Celery: received %s — initiating graceful shutdown", sig_name)
    app.control.broadcast("shutdown", destination=None)
    sys.exit(0)


# تسجيل handlers للإشارات
try:
    signal.signal(signal.SIGTERM, _graceful_shutdown)
except OSError:
    pass  # لا يمكن تسجيل SIGTERM في بعض البيئات

# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    app.start()
--- workers/celery_config.py
"""Celery Configuration — يدعم وضع in-memory بدون Redis لتطوير محلي.

للتشغيل بدون Redis:
    export CELERY_USE_MEMORY=1
    celery -A workers.celery_app worker --loglevel=info

للتشغيل مع Redis:
    export REDIS_URL=redis://localhost:6379/0
    celery -A workers.celery_app worker --loglevel=info
"""
from __future__ import annotations

import os
from datetime import timedelta

# ── Broker & Backend ────────────────────────────────────────────────────────

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# الوضع الافتراضي: in-memory إذا لم يكن Redis متاحاً
_use_memory = os.getenv("CELERY_USE_MEMORY", "1").lower() in ("1", "true", "yes")

if _use_memory:
    # in-memory broker للتطوير المحلي بدون Redis
    CELERY_BROKER_URL = "memory://"
    CELERY_RESULT_BACKEND = "cache+memory://"
else:
    CELERY_BROKER_URL = os.getenv("CELERY_BROKER_URL", REDIS_URL)
    CELERY_RESULT_BACKEND = os.getenv("CELERY_RESULT_BACKEND", REDIS_URL)

# ── Serialization ───────────────────────────────────────────────────────────
TASK_SERIALIZER = "json"
RESULT_SERIALIZER = "json"
ACCEPT_CONTENT = ["json"]

# ── Timezone ─────────────────────────────────────────────────────────────────
TIMEZONE = "UTC"
ENABLE_UTC = True

# ── Task routing ─────────────────────────────────────────────────────────────
TASK_DEFAULT_QUEUE = "default"
TASK_QUEUES = {
    "default":          {"exchange": "default",          "routing_key": "default"},
    "ingestion":        {"exchange": "ingestion",        "routing_key": "ingestion"},
    "processing":       {"exchange": "processing",       "routing_key": "processing"},
    "pipeline":         {"exchange": "pipeline",         "routing_key": "pipeline"},
    "monitoring":       {"exchange": "monitoring",       "routing_key": "monitoring"},
    # Phase 8 — AI Inference Queues
    "inference":        {"exchange": "inference",        "routing_key": "inference"},
    "inference_batch":  {"exchange": "inference_batch",  "routing_key": "inference_batch"},
    "inference_heavy":  {"exchange": "inference_heavy",  "routing_key": "inference_heavy"},
}

TASK_ROUTES = {
    "workers.tasks.ingestion_tasks.*":  {"queue": "ingestion"},
    "workers.tasks.processing_tasks.*": {"queue": "processing"},
    "workers.tasks.pipeline_tasks.*":   {"queue": "pipeline"},
    # Phase 8 — AI inference routing
    "inference.async_infer":            {"queue": "inference"},
    "inference.rag_chat":               {"queue": "inference"},
    "inference.batch_infer":            {"queue": "inference_batch"},
    "inference.analyze_document":       {"queue": "inference_heavy"},
}

# ── Retry ────────────────────────────────────────────────────────────────────
TASK_MAX_RETRIES = int(os.getenv("TASK_MAX_RETRIES", "3"))
TASK_DEFAULT_RETRY_DELAY = int(os.getenv("TASK_RETRY_DELAY", "30"))
TASK_ACKS_LATE = True
TASK_REJECT_ON_WORKER_LOST = True

# ── Results ──────────────────────────────────────────────────────────────────
RESULT_EXPIRES = int(os.getenv("RESULT_EXPIRES", str(60 * 60 * 24)))
TASK_STORE_EAGER_RESULT = True

# ── Worker ────────────────────────────────────────────────────────────────────
WORKER_PREFETCH_MULTIPLIER = int(os.getenv("WORKER_PREFETCH", "4"))
WORKER_MAX_TASKS_PER_CHILD = int(os.getenv("WORKER_MAX_TASKS", "1000"))
WORKER_CONCURRENCY = int(os.getenv("WORKER_CONCURRENCY", "4"))

# ── Monitoring ────────────────────────────────────────────────────────────────
WORKER_SEND_TASK_EVENTS = True
TASK_SEND_SENT_EVENT = True

# ── Beat schedule ─────────────────────────────────────────────────────────────
BEAT_SCHEDULE = {
    # Canonical production cadence.
    "health-check-every-5-min": {
        "task": "workers.tasks.ingestion_tasks.health_check_task",
        "schedule": timedelta(minutes=5),
        "options": {"queue": "monitoring"},
    },
    # Backward-compatible contract name retained for existing consumers.
    "health-check-every-minute": {
        "task": "workers.tasks.ingestion_tasks.health_check_task",
        "schedule": timedelta(minutes=5),
        "options": {"queue": "monitoring"},
    },
}
