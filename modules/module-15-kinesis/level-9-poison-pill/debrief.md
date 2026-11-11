# Debrief: one bad record can stop a shard

Kinesis guarantees order within a shard, so a Lambda event source mapping processes each shard serially and will not move past a batch it has not completed. If the function throws, the mapping **retries the same batch** (default: until the data expires, up to a year with extended retention). Nothing after the failing record is processed. This is the poison pill problem, and it is the Kinesis cousin of the SQS "bad apple" batch with one big difference: SQS lets other messages go on, a Kinesis shard cannot.

**The three levers**
- `MaximumRetryAttempts`: how many times a failing batch is retried (0 to 10,000; -1 means "until the record expires"). A small number turns an outage into a delay.
- `BisectBatchOnFunctionError`: after a failure, split the batch in two and retry each half separately. Repeated, this narrows a 10-record batch down to the one bad record in at most four rounds while the good halves succeed.
- `DestinationConfig.OnFailure`: where to send a *description* of the records that gave up. For Kinesis and DynamoDB streams this is metadata only (shard id, sequence number range, stream ARN), not the payload, so keep the stream long enough to fetch the record with `AT_SEQUENCE_NUMBER` and the range given in the message.

Also available: `MaximumRecordAgeInSeconds` (skip records older than this) and, for partial progress without bisecting, `FunctionResponseTypes: ["ReportBatchItemFailures"]`.

**Dropping data safely.** Hitting the retry limit *discards* the batch from the mapping's point of view. That is why the destination matters: without one, the poison record is gone and nobody knows.

**In real life**
- Validate at the edge when you can, but assume producers lie; a defensive `try/except` that parks the bad record yourself is an equally valid design.
- Alarm on `IteratorAge` for the function: a growing iterator age on one shard is the signature of a blocked shard.
