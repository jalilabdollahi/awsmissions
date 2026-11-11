# Debrief: versions are immutable, aliases are pointers

Step Functions gives you a release mechanism similar to Lambda's:

- **`update-state-machine`** changes the working copy. Executions started on the plain state machine ARN use it immediately.
- **`--publish`** freezes the current definition and role as a numbered **version** (`...:stateMachine:name:3`). A version can never change.
- An **alias** (`...:name:live`) is a named pointer to one version, or to two versions with weights (for example 90/10) for a canary release. Callers that use the alias ARN never change; you change where it points.

Rolling back is therefore just `update-state-machine-alias` to an older version number, which is why teams publish a version for every release. Marlin shows the catch: a version is a snapshot of the definition, *not* of the world it references. Version 1 still points at `marlin-fx-rates`; the function is gone, so version 1 can no longer run. Rolling back to a version that depends on retired infrastructure is not a rollback.

**Fix forward when you must.** Correct the defect in the working copy, publish a new version, point the alias at it. Check the Lambda ARNs of any version you roll back to before you route traffic to it.

**The bug itself.** Thresholds in a Choice are plain numbers with no unit. 1,000 euros is `1000`; the same amount in cents is `100000`. Nothing complains when the unit is wrong, the Choice is just never true. A boundary test (exactly the limit, one cent below) catches this class of bug, and the validator used those cases.

**In real life**
- Use aliases for any workflow that other systems start, and use canary routing (`weight=10`) only when both versions are safe to serve.
- Keep a version description per release (`--version-description`) so rollback decisions do not need archaeology.
- Alias changes are instant and need no deployment; make them the unit of rollout and watch `ExecutionsFailed` per version.
