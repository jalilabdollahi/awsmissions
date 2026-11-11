# Solution

A Firehose delivery stream has one of two **types**, fixed at creation: `DirectPut` (producers call `PutRecord`/`PutRecordBatch` on Firehose) or `KinesisStreamAsSource` (Firehose itself reads from a Kinesis data stream). `pageview-archive` is `DirectPut`, so it waits for data nobody sends it. The type cannot be edited, so the stream has to be replaced.

1. Confirm:

```bash
aws firehose describe-delivery-stream --delivery-stream-name pageview-archive \
  --query 'DeliveryStreamDescription.[DeliveryStreamType,Source]'
```

2. Delete it and recreate it with the same name, the same S3 destination (`archive.json` is a copy of it) and the Kinesis stream as source. The role already has the read permissions Firehose needs on `pageviews`:

```bash
aws firehose delete-delivery-stream --delivery-stream-name pageview-archive
aws firehose create-delivery-stream --delivery-stream-name pageview-archive \
  --delivery-stream-type KinesisStreamAsSource \
  --kinesis-stream-source-configuration "KinesisStreamARN=arn:aws:kinesis:us-east-1:000000000000:stream/pageviews,RoleARN=arn:aws:iam::000000000000:role/pageview-archive-role" \
  --extended-s3-destination-configuration file://archive.json
```

3. `check` publishes three events to `pageviews` (only to Kinesis) and waits for them under `raw/` in the archive bucket.
