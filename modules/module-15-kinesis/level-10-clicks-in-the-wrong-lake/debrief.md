# Debrief: Firehose only knows what the destination says

A Firehose delivery stream is a pipe with a fixed end: **bucket ARN + prefix + role**. It does not know about your Athena tables or Glue partitions, so if the bucket name or the prefix drifts, deliveries keep succeeding wherever they now point. In real AWS a nonexistent bucket makes deliveries fail (look for `S3.NoSuchBucket` in the `DeliveryToS3.Success` metric and in the error prefix); here, the bucket name you mistyped happened to be accepted, which is the nastier case, because there is nothing to alarm on.

**Prefixes and partitions.** Firehose evaluates expressions in the prefix when it flushes a buffer:
- `!{timestamp:yyyy-MM-dd}` (and `HH`, `MM`, ...) uses the **arrival time in UTC**, not the event time;
- `!{firehose:random-string}` and `!{firehose:error-output-type}` for sharded or error prefixes;
- with dynamic partitioning enabled you can also use `!{partitionKeyFromQuery:key}` to partition by a field of the data.

Hive-style `dt=...` folders let Athena prune partitions; a plain `YYYY/MM/DD/` prefix (the default when you leave the prefix empty) needs partition projection or a crawler to be queryable by `dt`.

**Changing a destination.** `UpdateDestination` needs the current `VersionId` (a guard against two people updating at once) and the `DestinationId`. Only fields you provide change; the stream keeps running, and records already buffered flush to the old place.

**In real life**
- Keep the bucket name and prefix in one IaC variable shared by the Firehose and the Athena/Glue definitions.
- Alarm on "no objects written under the expected prefix in the last N minutes", not just on Firehose errors.
- Existing objects in the wrong place are not moved by the fix; copy them with `aws s3 sync` if you need them.
