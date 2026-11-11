# Debrief: INC-3318, the stack that would not update

## Root causes
1. **Export-name collision.** CloudFormation export names must be unique per region. The migration template reused `cobalt-orders-queue-arn`, which `cobalt-core` already exports, so creation failed after some resources already existed.
2. **No `DeletionPolicy` on a stateful resource.** The failed stack held a table that finance had begun to fill. "Delete and recreate" would have wiped it.
3. **Function configuration.** Wrong table name in the environment.
4. **Function role.** No read permission on the table. Both 3 and 4 are runtime failures that the stack deploy never tests.

## Timeline
- CHG-2207 window: stack created, ends `CREATE_FAILED` on the export.
- Same afternoon: finance starts writing ledger entries into the table since it exists.
- Next morning: deploy bot refuses to update; the proposed remedy is delete and recreate.
- Resolution: fix the template, update in place, add Retain.

## What CloudFormation did
A stack create is not atomic in practice: resources created before the failure may remain, and on real AWS a rollback would usually delete them (a `ROLLBACK_COMPLETE` stack must be deleted before reuse, which is exactly why Retain matters first). Retained resources are *orphaned* on delete: they keep living but are no longer managed by any stack.

## Lessons
- Put `DeletionPolicy: Retain` (and `UpdateReplacePolicy: Retain`) on every stateful resource from the first deploy, not after the first scare.
- Namespace exports with the stack name (`${AWS::StackName}-LedgerArn`) to make collisions impossible.
- Never let production data into a stack that is not yet healthy. Gate real traffic on `*_COMPLETE`.
- A green deployment is not a working application. Add a post-deploy smoke test that invokes the function.
