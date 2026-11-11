# Debrief: the stack lifecycle, and the one state you cannot update

| State | Meaning | What you can do |
|---|---|---|
| `CREATE_COMPLETE` / `UPDATE_COMPLETE` | healthy | update, delete |
| `UPDATE_ROLLBACK_COMPLETE` | an update failed and was undone | update again, delete |
| `ROLLBACK_COMPLETE` | the *initial create* failed and was undone | **delete only** |
| `*_FAILED`, `*_IN_PROGRESS` | something is mid-flight or stuck | wait, `continue-update-rollback`, or delete |

A stack in `ROLLBACK_COMPLETE` has no resources, so there is nothing to "update from". Keeping the shell lets you read the events that explain the failure; deleting it frees the name.

**Why it happened.** The api stack used `Fn::ImportValue`, a runtime lookup of another stack's export. Imports are resolved when the resource is created, so deploy order matters. The release train should deploy `saltmarsh-shared` first.

**In real life**
- Encode ordering in your pipeline (stage 1: shared, stage 2: consumers), or avoid hard cross-stack imports for things that change often: an SSM parameter written by the producer and read as a parameter type (`AWS::SSM::Parameter::Value<String>`) is looser coupled.
- Remember that real CloudFormation will not let you delete or change an export while another stack imports it. That protects consumers but also makes exports hard to evolve.
- `create-stack --on-failure DO_NOTHING` (or `--disable-rollback`) keeps the half-built resources, which is handy when debugging a first deploy, but you must clean them up yourself.
