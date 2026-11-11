# Debrief: ordering is a property of the queue type

**Standard queues** scale almost without limit but offer *at-least-once* delivery and *best-effort* ordering. Messages are spread over many servers, so a later message can overtake an earlier one. **FIFO queues** guarantee order and exactly-once processing within a *message group*, at a lower throughput (300 messages/s per API action, 3,000 with batching, higher with high-throughput mode).

**Message groups are the key design decision.** Ordering holds only within one `MessageGroupId`. One global group serialises everything (the whole queue becomes a single lane); one group per account, order or device keeps ordering where it matters and still lets consumers work in parallel. While one message of a group is in flight, no later message of that group is delivered to anyone else.

**Why the queue could not be fixed in place.** `FifoQueue` can only be set at creation time, and a FIFO queue's name must end with `.fifo`. Migrating means creating the new queue, switching producers, draining the old queue, then deleting it.

**In real life**
- Ordering only helps if the producer sends in order too: a multi-threaded sender can already reorder before SQS sees the messages.
- Every FIFO send needs a deduplication id, or `ContentBasedDeduplication` must be on (see the next level).
- Prefer idempotent consumers even with FIFO; "exactly-once" holds only inside the 5-minute deduplication window.
