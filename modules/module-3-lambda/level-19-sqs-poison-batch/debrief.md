# Debrief: SQS batches succeed or fail together, unless you say otherwise

An SQS event source mapping hands your function up to `BatchSize` messages at once. By default the contract is all-or-nothing: if the invocation succeeds, **every** message in the batch is deleted; if it raises, **none** are, and all of them become visible again after the queue's visibility timeout. Each reappearance increments the message's receive count, and when that reaches the redrive policy's `maxReceiveCount`, SQS moves it to the dead-letter queue.

One poison message therefore causes two kinds of damage:
- **Duplicate processing** of every healthy neighbour (the ledger's `attempts` counter shows 3).
- **False dead-lettering**: healthy messages land in the DLQ because they shared a batch with a bad one.

**Partial batch response** fixes both. Enable `FunctionResponseTypes: ["ReportBatchItemFailures"]` on the mapping and return `{"batchItemFailures": [{"itemIdentifier": "<messageId>"}]}`. Lambda then deletes the messages not listed, and only the listed ones go back for retry and, eventually, to the DLQ.

Details that bite:
- The mapping setting and the code change are a pair. If the mapping has not enabled the feature, the returned list is ignored and the batch counts as success, so **failures are silently deleted**. Likewise, raising an exception instead of returning the list still fails the whole batch.
- Returning an empty list or `null` means total success. A missing `itemIdentifier` is treated as total failure.
- Keep the queue's visibility timeout at least 6x your function timeout, and set `maxReceiveCount` high enough for transient errors (3 to 5), low enough that poison pills move out quickly.
- Even with partial responses, SQS is at-least-once: make the processing idempotent (conditional writes or an idempotency key) rather than counting attempts.

**In real life**
- Alarm on `ApproximateNumberOfMessagesVisible` of the DLQ and give it a long retention period.
- AWS Lambda Powertools provides a `BatchProcessor` that implements this pattern for you.
- FIFO queues need extra care: stop at the first failure so ordering is not violated.
