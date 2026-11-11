# Debrief: PutRecord and PutRecords are different permissions

Kinesis IAM actions map one to one onto API calls. A producer that calls `PutRecords` needs `kinesis:PutRecords`; `kinesis:PutRecord` does not cover it, and neither implies the other. Stream-level actions are authorised against the **stream ARN** (`arn:aws:kinesis:<region>:<account>:stream/<name>`), so a policy scoped to the staging stream is useless for production, however similar the names look.

**What "write-only" looks like.** A scanner needs the two put actions and nothing else. Read actions (`GetShardIterator`, `GetRecords`, `SubscribeToShard`) belong to consumers; `DescribeStream*` / `ListShards` belong to tooling. Splitting producer and consumer identities means a leaked scanner key can pollute the stream but cannot read customer data back.

**Why not `kinesis:*` on `*`?** It would also have fixed the symptom, and it would also have let the depot scanners write to `parcel-billing`, delete streams and change their shard count. Kinesis is cheap to scope: one statement, one ARN.

**In real life**
- A wrong or missing action shows up as `AccessDeniedException ... not authorized to perform: kinesis:PutRecords on resource: <arn>`. The message names both the action and the ARN, so read it before you guess.
- Copying a policy between environments is the usual origin of this bug. Template the ARN from the stream name in IaC and the problem disappears.
- The KPL and Firehose-style libraries batch with `PutRecords`; `put_record` calls in SDK snippets do not tell you what the production client actually uses.
