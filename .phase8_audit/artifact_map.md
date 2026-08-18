# Artifact Map

The Phase 8 runtime artifact contract must be compatible with the Phase 6 lifecycle and existing `ModelRegistry` authority.

Required fields: `model_id`, `model_version`, `artifact_path`, `artifact_checksum`, tokenizer metadata, architecture metadata, `training_run_id`, dataset version/checksum, benchmark/evaluation id, evaluation metrics, and approval status.

Required gate:

`artifact valid AND training complete AND evaluation complete AND required metrics pass AND registry approved`.

A successful file load alone is insufficient. Invalid, unapproved, checksum-mismatched, incomplete, or metadata-incompatible artifacts must be rejected before loading. No fake artifact or checkpoint is created by Phase 8.
