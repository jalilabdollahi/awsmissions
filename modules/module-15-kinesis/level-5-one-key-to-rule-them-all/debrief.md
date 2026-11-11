# Debrief: the partition key is the whole sharding story

A shard accepts at most 1 MB or 1,000 records per second. Which shard a record goes to is decided only by its partition key: `MD5(key)` becomes a 128-bit number, and each shard owns a contiguous slice of that range. Adding shards does nothing for a constant key, because one value always falls in the same slice.

**Two properties you want from a key**
1. **High cardinality**: many distinct values, so the hash spreads load. A constant, a region name or a boolean is a hot-shard bug waiting for traffic.
2. **Meaningful grouping**: records that must be processed in order share a key. Kinesis orders records *within a shard*, so everything with the same key is ordered and nothing across keys is. A random UUID per record spreads perfectly and destroys per-order ordering.

The order id satisfies both for Quillbox. Be careful with keys that are *skewed* even when varied: `customer_id` is great until one enterprise customer produces 40% of the traffic.

**Spotting it in real life**
- CloudWatch `WriteProvisionedThroughputExceeded` on one shard while `IncomingBytes` is far below the stream's total capacity.
- Enhanced shard-level metrics (`aws kinesis enable-enhanced-monitoring --shard-level-metrics ALL`) show per-shard `IncomingBytes`, which confirms the diagnosis.
- `PutRecords` returns per-record `ShardId`s: log them in a test run to see the distribution before you ship.

**If a key really is hot**, you can add an explicit hash key (`--explicit-hash-key`), salt the key (`customer-17#0..3`) at the cost of weaker ordering, or split the shard that owns the hot range.
