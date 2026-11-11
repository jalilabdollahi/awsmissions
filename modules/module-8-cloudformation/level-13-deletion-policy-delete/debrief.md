# Debrief: DeletionPolicy decides what survives

`DeletionPolicy` is a resource attribute that tells CloudFormation what to do when the resource is removed from a stack, either because the stack is deleted or because the resource was dropped from the template:

| Value | Effect |
|---|---|
| `Delete` (default) | the real resource is deleted |
| `Retain` | the real resource is kept; CloudFormation just forgets it |
| `Snapshot` | take a final snapshot (EBS, RDS, ElastiCache, Redshift, Neptune, DocumentDB), then delete |

**Order matters.** The policy used is the one stored with the *deployed* stack. Editing a local file does nothing until an `update-stack`; a delete issued first would have used the old, default policy.

**What each shortcut would have cost**
- Plain `delete-stack`: the table goes (data lost) and the stack stalls in `DELETE_FAILED` on the non-empty bucket.
- Emptying the bucket to unblock the delete: the ledger exports are gone.
- Retained resources are orphans afterwards: nobody bills them to a stack, and a later `create-stack` with the same names will clash.

**Related attributes**
- `UpdateReplacePolicy` covers the other way a resource disappears: replacement during an update.
- A bucket policy that denies `s3:DeleteBucket`, DynamoDB deletion protection and RDS `DeletionProtection` add independent guards. Production stateful resources should use several layers.
- Termination protection on the stack (see the Policy Lock mission) stops the delete before it starts.
