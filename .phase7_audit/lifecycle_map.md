# Canonical Lifecycle Map

```text
OBSERVED
  -> HYPOTHESIS_CREATED
  -> EXPERIMENT_PLANNED
  -> EXPERIMENT_RUNNING
  -> EXPERIMENT_COMPLETED
  -> EVALUATING
  -> EVALUATED
  -> APPROVAL_PENDING / approval gate
  -> APPROVED
  -> VERSIONED
  -> STAGED
  -> DEPLOYING
  -> DEPLOYED
  -> ROLLED_BACK
```

## Failure transitions

```text
missing evidence / missing hypothesis
  -> rejected or failed

missing executor / timeout / executor exception
  -> FAILED, result remains absent

missing reflector or evaluator
  -> FAILED

missing metric / failed threshold / regression
  -> FAILED or REJECTED; no approval

policy denial
  -> REJECTED

missing ModelRegistry lineage when registry is injected
  -> FAILED; no version/deployment

deployer failure
  -> FAILED; no successful deployment event

rollback without deployed record/rollbacker
  -> FAILED; no state mutation to production

explicit cancellation
  -> CANCELLED; no result is created
```

## Forbidden transitions

`OBSERVED -> DEPLOYED`, `HYPOTHESIS_CREATED -> DEPLOYED`, and `EXPERIMENT_COMPLETED -> DEPLOYED` are not permitted. Deployment requires evaluation, policy approval, versioning, and an explicit deployer.

## Trace requirements

Every canonical record carries an experiment identifier and trace events. Events include state transitions, errors, metrics/provenance where available, approval/version/deployment references, and rollback references.
