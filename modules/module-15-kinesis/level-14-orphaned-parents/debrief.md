# Debrief: after a reshard, the stream is a tree

`UpdateShardCount`, `SplitShard` and `MergeShards` all work the same way: the old shard(s) are **closed** (they get an ending sequence number and a `ChildShards` list) and new shards are created with `ParentShardId` (and `AdjacentParentShardId` for merges). The closed shard stays readable until its records expire. After two reshards a long-retention stream can hold live data in the leaves and history in the inner nodes.

**What a correct consumer does**
1. Discover shards dynamically (`ListShards`, paginated), never with a constant list or a shard count you remembered.
2. Read a shard until `GetRecords` stops returning a `NextShardIterator`: that is the end of a closed shard (the response also names the children).
3. **Parent before child.** Kinesis orders records only within a shard. Records for one partition key before the reshard are in the parent and the ones after are in a child; to keep that key's order, finish the parent first. Different parents/children can be read in parallel once their own parent is done.

That ordering rule is exactly what the KCL implements with its lease table (it will not start a child lease until the parent is complete), and what Lambda event source mappings do for you. Scripts and one-off jobs are where the rule is forgotten.

**Pitfalls**
- Filtering to *open* shards (`ShardFilter` of `AT_LATEST`, or "EndingSequenceNumber is null") is right for a live tail and wrong for an export or a replay.
- A shard iterator created with `LATEST` on a parent returns nothing: the parent will not receive new writes.
- `DescribeStream` also lists shards but is capped at 10 calls per second per stream and gives a limited page; `ListShards` is the supported way.

**In real life** treat resharding as a normal event in the life of a stream, test your consumers against a stream that has been split and merged at least once, and alarm on `IteratorAgeMilliseconds` per shard so a consumer that silently ignores new shards is noticed.
