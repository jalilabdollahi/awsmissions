# Debrief: who calls whom decides the delivery stream's type

Firehose can be fed in two ways, and the choice is permanent:

| Type | How data gets in | Typical use |
|---|---|---|
| `DirectPut` | the producer calls Firehose (`PutRecord`, `PutRecordBatch`), or AWS services such as CloudWatch Logs, WAF, IoT push to it | you have no stream, only a sink |
| `KinesisStreamAsSource` | Firehose reads a Kinesis data stream itself | the stream exists for real-time consumers and Firehose only adds an archive/ETL branch |

A direct-put stream attached to nothing is perfectly healthy, which is why this failure is silent: no errors, no throttling, just zero incoming records.

**Why the Kinesis source is the right fit here.** The apps publish once, to Kinesis. Firehose becomes one more *consumer* of the stream, so the dashboards are unaffected and the archive cannot fall out of step with what they see. When the source is a Kinesis stream, producers must **not** also call `PutRecord` on that delivery stream (AWS rejects it).

**What it costs the stream.** Firehose reads like any classic consumer: it uses a share of the shard's 2 MB/s read limit and 5 reads/s (it does not use enhanced fan-out), and it needs a role with `kinesis:DescribeStream`, `GetShardIterator`, `GetRecords` and `ListShards`. A role that can write S3 but not read Kinesis creates a stream that looks fine and moves nothing.

**In real life**
- Since type and source cannot be changed, set them in IaC from day one, and test that the bucket receives data before you declare the pipeline done.
- Firehose reads from the point where the delivery stream is created, so recreating it can skip or repeat events around the swap; plan the switch for a quiet moment, or replay the stream into the bucket for the gap.
- Watch the delivery stream's `DataReadFromKinesisStream.Bytes` metric: zero while the stream has traffic means the wiring is wrong.
