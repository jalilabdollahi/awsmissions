# Debrief: how a FIFO queue decides "this is the same message"

A FIFO queue keeps a **deduplication cache of 5 minutes**. A message whose deduplication id was already seen is accepted (the send call succeeds and even returns the first message's id) but not enqueued again. Where the id comes from:

1. The producer sets `MessageDeduplicationId` explicitly. Best when you have a natural key such as a payment id.
2. The queue has `ContentBasedDeduplication=true`, and SQS uses a SHA-256 of the **body** (message attributes are not hashed).
3. Neither: the send fails with `InvalidParameterValue`, which is what the webhook saw.

**Consequences to know**
- Content-based ids deduplicate *identical bodies*, even when two real, separate events are identical (two coffee orders in one minute). If bodies can legitimately repeat, put a unique field (an event id or timestamp) inside the body, or use explicit ids.
- Deduplication protects the *enqueue* side only. A consumer that fails and receives a message twice is a separate problem, solved with idempotent processing.
- The window is exactly 5 minutes. A gateway that retries for longer needs idempotency at the consumer too.

**In real life**
- For money, prefer an explicit id derived from the payment (for example `capture-<payment id>`) and keep content-based deduplication only as a safety net.
- `DeduplicationScope` and `FifoThroughputLimit` control whether deduplication is per queue or per message group in high-throughput mode.
