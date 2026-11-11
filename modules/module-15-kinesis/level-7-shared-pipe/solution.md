# Solution

All classic ("shared throughput") consumers of a stream draw from one 2 MB/s per-shard read allowance and from a limit of 5 `GetRecords` calls per second per shard. **Enhanced fan-out** gives a registered consumer its own 2 MB/s per shard, pushed to it over HTTP/2 (`SubscribeToShard`). A Lambda mapping uses it when its event source is the **consumer ARN** instead of the stream ARN.

1. See the current layout:

```bash
aws lambda list-event-source-mappings --function-name risk-scorer
aws kinesis list-stream-consumers --stream-arn arn:aws:kinesis:us-east-1:000000000000:stream/trade-ticks
```

2. Register a consumer for risk-scorer and wait until it is `ACTIVE`:

```bash
aws kinesis register-stream-consumer \
  --stream-arn arn:aws:kinesis:us-east-1:000000000000:stream/trade-ticks \
  --consumer-name risk-scorer-efo
aws kinesis describe-stream-consumer --consumer-arn <ConsumerARN>
```

3. Create a new mapping on the consumer ARN (the source of a mapping cannot be edited) and then delete the old one, otherwise every trade is scored twice:

```bash
aws lambda create-event-source-mapping --function-name risk-scorer \
  --event-source-arn <ConsumerARN> --starting-position LATEST --batch-size 50
aws lambda delete-event-source-mapping --uuid <old UUID>
```

4. `check` inspects the mapping, publishes four trades and expects each to be scored once and booked once.
