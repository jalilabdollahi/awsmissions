# Debrief: enhanced fan-out gives each consumer its own pipe

**Shared throughput (classic).** Every consumer calls `GetRecords` on the same shard, and together they share 2 MB/s and 5 calls per second. Three consumers get roughly a third each, and each extra reader slows the others. The symptom is `ReadProvisionedThroughputExceeded` and a growing `IteratorAgeMilliseconds`.

**Enhanced fan-out (EFO).** You register a *named consumer* on the stream (`RegisterStreamConsumer`, up to 20 per stream). Kinesis then pushes records to it over a persistent HTTP/2 connection at up to 2 MB/s per shard, per consumer, with typically ~70 ms latency instead of ~200 ms polling. Consumers do not affect each other or the shared pool.

**Using it from Lambda.** Point the event source mapping at the *consumer ARN*. The stream and the consumer are different resources, and the mapping's source cannot be edited afterwards: you create a new mapping and delete the old one. In real AWS, create the new mapping first and let both run briefly (or start the new one from `AT_TIMESTAMP`) to avoid a gap, and make the function idempotent so overlap is harmless. Deleting first loses events that arrive in between; keeping both double-processes them.

**Trade-offs**
- EFO is priced per consumer-shard-hour plus per GB retrieved, so it is not free; use it for latency-sensitive or contended readers and leave batch readers on shared throughput.
- A consumer must be re-registered if you delete and recreate the stream; the ARN includes a creation timestamp.
- The same idea exists in the KCL (`retrievalSpecificConfig` with fan-out) for non-Lambda consumers.
