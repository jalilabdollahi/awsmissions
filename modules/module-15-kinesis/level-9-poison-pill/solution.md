# Solution

For a Kinesis source Lambda does **not** skip a failing batch: it retries the same records until they succeed or expire, because it must preserve order within a shard. By default there is no retry limit, so a single unparsable reading blocks everything behind it. The mapping has three settings that change this.

1. Inspect the mapping:

```bash
aws lambda list-event-source-mappings --function-name vitals-alerter
```

2. Limit retries, split failing batches in half so the good records are isolated, and send the records that finally fail to the SQS queue:

```bash
aws lambda update-event-source-mapping --uuid <UUID> \
  --maximum-retry-attempts 2 \
  --bisect-batch-on-function-error \
  --destination-config '{"OnFailure":{"Destination":"arn:aws:sqs:us-east-1:000000000000:vitals-dead-letters"}}'
```

3. `check` writes good, bad, good into the stream, waits for both good readings (and the five that were already there) to be stored, and looks in `vitals-dead-letters` for a failure record whose sequence range covers the bad reading.
