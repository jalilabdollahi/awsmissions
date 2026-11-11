# Debrief: streams are change data capture, and the view type is the contract

A DynamoDB stream is an ordered log (24 hour retention) of item-level changes per partition key. Consumers (Lambda event source mapping, Kinesis adapter, your own poller) read from it. A stream only records changes made **after** it is enabled. Nothing is back-filled, which is why enabling it later never recovers history.

`StreamViewType` decides what each record carries:
- `KEYS_ONLY`: just the key attributes of the changed item.
- `NEW_IMAGE`: the item after the change.
- `OLD_IMAGE`: the item before the change.
- `NEW_AND_OLD_IMAGES`: both. Required for diffs, auditing and "what changed" notifications.

Pick the smallest view that serves the consumer, because bigger images mean bigger records to process (the stream itself costs only read request units).

Good to know:
- Event names are `INSERT`, `MODIFY`, `REMOVE`. A put that changes nothing still produces no MODIFY.
- Order is guaranteed per item key, not across the table.
- Writes are never blocked or slowed by consumers. If the consumer falls behind by more than 24 hours, records are gone.
- Lambda consumers need `dynamodb:GetRecords`, `GetShardIterator`, `DescribeStream`, `ListStreams` on the stream ARN. The ARN changes if you disable and re-enable the stream.
- TTL deletions show up as REMOVE events with a service principal identity, so audit consumers can tell them apart from user deletes.
