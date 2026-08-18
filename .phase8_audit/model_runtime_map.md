# Model Runtime Map

## Existing

`BrainV3` owns the central request pipeline and receives a `ModelRouter`. API routes delegate to BrainV3. Native streaming interfaces exist at the Brain/API boundary.

## Not proven as available

No verified real Hajeen checkpoint, linked tokenizer, approved artifact, successful model load, runtime readiness, or production inference capability was found during the code audit. The presence of a model-facing API facade is not proof of a loaded model.

## Required runtime states

`UNCONFIGURED → DISCOVERING → VALIDATING → LOADING → READY`, with any failure transitioning to `FAILED`. Public error states must distinguish `MODEL_NOT_CONFIGURED`, `ARTIFACT_NOT_FOUND`, `ARTIFACT_INVALID`, `CHECKSUM_MISMATCH`, `TOKENIZER_INVALID`, `ARCHITECTURE_MISMATCH`, `MODEL_LOAD_FAILED`, `DEVICE_UNAVAILABLE`, and `INFERENCE_UNAVAILABLE`.

## Required metadata

Every runtime and inference trace must carry `model_id`, `model_version`, `artifact_checksum`, `device`, `dtype`, load/inference timing, streaming capability, provider/backend, request id, and error state without secrets or raw sensitive prompts.

## Safety conclusion

Until a real approved artifact is supplied and loaded, runtime readiness must remain false and inference must fail closed. Tests may use doubles only inside the Phase 8 test module.
