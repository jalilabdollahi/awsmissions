# Debrief: events have names, and they are not interchangeable

S3 groups its notifications into families:

| Family | Fires on |
|---|---|
| `s3:ObjectCreated:*` | Put, Post, Copy, CompleteMultipartUpload |
| `s3:ObjectRemoved:*` | Delete, DeleteMarkerCreated |
| `s3:ObjectRestore:*`, `s3:LifecycleExpiration:*`, `s3:Replication:*`, ... | specialised events |

A rule subscribed to the wrong family is not an error; it is simply a different, valid rule. Because the queue exists and the configuration saved fine, the only symptom is an absence of messages for the thing you care about, and a flood of messages for the thing you do not.

**What the test proves**
The validator generates every combination (create or delete, `uploads/` or `originals/`) and checks both queues. A "fix" that just widens the rule to `s3:*` would send deletes to the thumbnail worker, and would be caught.

**In real life**
- Look at `eventName` inside the record (`ObjectCreated:Put`, `ObjectRemoved:Delete`) when debugging; it tells you instantly which family fired.
- On real S3, two rules with overlapping prefixes and overlapping events are rejected, so one prefix can have only one consumer per event family. Use SNS or EventBridge to fan out.
- `PutBucketNotificationConfiguration` replaces everything. Treat it like a database `UPDATE` without a `WHERE`: read first, edit, write back the full document.
