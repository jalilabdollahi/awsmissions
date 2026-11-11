# Solution

Kinesis picks the shard for a record by hashing its **partition key** (MD5) and finding the shard that owns that hash range. `publisher.py` uses the same constant key, `"order-service"`, for every record, so all of Quillbox's traffic hashes to one value and therefore to one shard. The other three shards are idle however well sized the stream is.

1. See where the records go:

```bash
aws lambda invoke --function-name order-publisher --cli-binary-format raw-in-base64-out \
  --payload '{"events":[{"order_id":"A1","type":"created"},{"order_id":"B2","type":"created"}]}' out.json
aws kinesis put-record --stream-name order-events --partition-key order-service --data eA== --query ShardId
```

2. Use a key with high cardinality that still groups what must stay in order: the order id. In `publisher.py` (`edit`) replace the constant with `item["order_id"]`.

3. Package and deploy:

```bash
zip publisher.zip publisher.py
aws lambda update-function-code --function-name order-publisher --zip-file fileb://publisher.zip
```

4. `check` publishes 36 events for 12 orders, reads every shard back, and verifies two things: the events are spread over several shards, and no order is split across shards. A random key per record would pass the first test and fail the second.
