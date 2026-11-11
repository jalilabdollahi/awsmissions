# Debrief: Number parameters, and what a failed create leaves behind

**Types are about the value, not the unit.** `Type: Number` means the value must be an integer or float literal. Units belong in the parameter's name or description (`TimeoutSeconds`), never in the value. Real CloudFormation rejects `"45s"` for a `Number` parameter during validation; this emulator lets it through and the downstream service fails instead. Either way the cure is to fix the input.

**What the failed run left behind.** When a resource fails during *create*, CloudFormation deletes everything it made and parks the stack in `ROLLBACK_COMPLETE`. Such a stack:
- keeps its name and its event history (very useful for debugging),
- cannot be updated,
- must be deleted before you can reuse the name.

An *update* that fails behaves differently: the stack returns to the previous good state (`UPDATE_ROLLBACK_COMPLETE`) and remains updatable.

**Practical tips**
- Read `describe-stack-events` from the newest entry down; the first `CREATE_FAILED` row has the root cause and later rows are usually fallout.
- Keep per-environment parameter files in git and validate them in CI so a typo cannot reach the pipeline.
- Use `AllowedPattern`/`MinValue`/`MaxValue` on numeric parameters so the template documents its own limits. Real CloudFormation enforces them before any resource is touched.
- For a first deploy that you expect to iterate on, `create-stack --on-failure DO_NOTHING` keeps the failed resources around for inspection instead of rolling back.
