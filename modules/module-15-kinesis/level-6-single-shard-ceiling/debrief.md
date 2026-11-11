# Debrief: capacity is shards, and resharding is a graph, not a switch

**Limits per shard:** writes 1 MB/s or 1,000 records/s; reads 2 MB/s shared by classic consumers. Stream capacity is the sum over *open* shards, so scaling is just changing how many there are.

**What `UpdateShardCount` really does.** It does not "resize" shards. It *closes* the existing shards and creates new child shards whose hash ranges tile the same 128-bit key space, each remembering its `ParentShardId`. The parents stay readable until their data ages out of retention, which is why the history survived. It is an in-place operation, so producers and consumers keep their stream name and ARN.

**The rules you just met**
- One call can at most double (or halve) the open shard count; there are also per-account limits on how many scaling operations you can run per day.
- Scaling UNIFORM keeps shards equal in size. If a single shard is hot, splitting just that one (`split-shard`) is cheaper than doubling everything.
- Only the partition keys decide traffic spread: more shards help only if keys are varied (see the constant-key mission).

**In real life**
- On-demand mode (`StreamMode=ON_DEMAND`) scales write capacity automatically and removes this whole exercise, at a higher unit price; provisioned mode wins when traffic is predictable.
- A consumer must follow the parent/child relationship when you reshard: finish the parent before reading its children, or ordering breaks. Lambda event source mappings and the KCL handle it for you; hand-written readers must not forget it.
- Capacity planning works from the **peak**, not the average, plus headroom: at 3 MB/s on 3 shards you have no room for a retry storm.
