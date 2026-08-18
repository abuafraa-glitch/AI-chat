# Phase 6 Audit — Lifecycle and Authority Map

## Baseline

- Branch: `master`
- Phase 5 baseline: native streaming, BrainV3, ModelRouter, MemoryFabric, RAGPipeline, AgentOrchestrator, typed ToolRuntime.
- Rule: no fake data, fake training, fake evaluation, or implicit remote model download.

## Actual lifecycle observed

```text
ChannelRegistry / API task trigger
  -> workers.tasks.ingestion_tasks.run_channel_ingestion
  -> channel.fetch()
  -> channel.run_pipeline()
  -> storage layers / repositories

Raw records
  -> DataPreparationPipeline.validate_dataset
  -> LanguageDetector.filter_unsupported_languages
  -> QualityScorer.score_dataset
  -> Deduplicator.deduplicate_dataset
  -> returned list only; no canonical DatasetVersion or lifecycle record

Raw samples
  -> ContinuousLearningPipeline.run
  -> collection
  -> cleaning
  -> exact + embedding deduplication
  -> quality validation
  -> filtering/ranking
  -> optional human approval
  -> JSONL dataset artifact
  -> training_queue.json
  -> local-checkpoint-only fine-tuning or deferred status
  -> local-only evaluation or non-deployable result
  -> deployment/rollback decision

DatasetVersioner.create_version
  -> quality filter
  -> exact-text deduplication
  -> checksum
  -> filesystem artifact + versions.json
  -> no explicit status/approval/lineage graph

ModelRegistry
  -> in-process ModelConfig listing only
  -> consumed by /models and runtime metadata
  -> no artifact, evaluation, approval, lineage, or persistent promotion lifecycle
```

## Canonical authorities after Phase 6 design

| Concern | Existing authority | Phase 6 decision |
|---|---|---|
| Raw/processed storage | `StorageManager` and layer stores | Keep as storage authority; pipeline records references, not duplicate stores |
| Ingestion trigger | Celery workers / channel pipeline | Keep as source adapter; route outputs into dataset lifecycle |
| Cleaning/validation | `DataPreparationPipeline` plus helpers | Wrap and normalize into typed run stages; preserve deterministic implementations |
| Deduplication | `Deduplicator`, `StorageManager`, `DatasetVersioner`, learning pipeline | Define one dataset-stage policy and persist counts/reasons |
| Dataset version | `DatasetVersioner` | Extend with explicit status, source, validation, split, and lineage metadata |
| Training execution | `TrainingPipeline`, `core.training_engine`, `ContinuousLearningPipeline` | Keep mechanics lower-level; use one lifecycle coordinator and fail closed |
| Evaluation | `core.training_engine.evaluator`, learning evaluation | Add typed evaluation run and threshold result; no approval without real artifact |
| Model runtime metadata | `core.model.ModelRegistry` | Preserve `/models` compatibility; extend lifecycle separately or add backward-compatible artifact records |
| Model routing | `ModelRouter` | Remains sole runtime provider selector; only approved artifacts may be registered for runtime |
| Brain/API | `BrainV3` | Remains inference authority; no training logic inserted into request path |
| Lineage | `LineageTracker` | Use as persistence primitive for dataset -> training -> evaluation -> model edges |

## Critical gaps found

1. `ContinuousLearningPipeline` has persisted run state but its historical comment says simulation; current fine-tuning is fail-closed and deferred without local checkpoint, while evaluation is non-deployable without a real local artifact. This must remain explicit and must not be reported as successful training.
2. `DatasetVersioner` has checksum and filesystem persistence, but `DatasetVersion.to_dict()` omits `metadata`, `is_train`, and `is_valid`; there is no accepted/rejected/blocked status machine or validation evidence.
3. `DataValidator` mutates records with basic validity fields but does not create a run-level report, rejection reasons aggregate, language decision, or provenance.
4. `DataPreparationPipeline` returns a list and prints progress; it does not persist a run id, deterministic manifest, or source lineage.
5. `ModelRegistry` is only an in-process `ModelConfig` registry and must not be treated as an artifact promotion authority without backward-compatible extension.
6. `TrainingPipeline` and `trainer.py` execute raw mechanics but do not own `TrainingRun`, dataset gate, artifact manifest, or approval state.
7. Evaluation helpers compute metrics but do not own evaluation-run persistence, benchmark identity, artifact checksum, or promotion decision.
8. `LineageTracker` is a low-level SQL record writer and must be called by the canonical lifecycle coordinator rather than by every helper.

## Required invariants

- No training starts unless the dataset is valid, versioned, and approved for training.
- No evaluation passes without loading a real local artifact and a real evaluation dataset.
- No model becomes runtime-approved without evaluation thresholds and artifact integrity validation.
- Failed/deferred training and evaluation remain non-promotable.
- No phase creates a second ModelRouter, Memory authority, RAG authority, or prompt builder.
- Every run has a stable id, status, timestamps, input/output references, checksum, and lineage edges.
