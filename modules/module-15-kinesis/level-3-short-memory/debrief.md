# Debrief: retention is your replay budget

A Kinesis stream is a log, not a queue: consumers do not delete records, the stream does, once they are older than the retention period (default 24 hours). Everything about **replay** depends on that number. A consumer that was down longer than the retention window comes back to find a gap that cannot be recovered; its iterator simply starts at the oldest record that is left.

**Sizing it:** retention should be at least *(longest outage you want to survive) + (time to catch up) + margin*. Catching up is not free: a consumer replaying three days of data must read faster than the live write rate, so remember per-shard read limits (2 MB/s, shared between classic consumers) when you estimate the time.

**Cost tiers:** 24 hours is included in the shard-hour price; 25 hours to 7 days costs an extra per-shard-hour; beyond 7 days it is billed as long-term retention (per GB-month) on top. That is why the mission caps the answer at 168 hours.

**Why not recreate the stream?** `IncreaseStreamRetentionPeriod` is an in-place, instant change: nothing is lost, no ARN changes, no producer or consumer has to be touched. Recreating would have thrown away the very data you want to protect.

**In real life**
- You can lower retention too (`decrease-stream-retention-period`), but records older than the new period become unreadable almost immediately.
- To replay from a point in time, use a shard iterator of type `AT_TIMESTAMP`; it only works if that moment is still inside the retention window.
- Alarm on `GetRecords.IteratorAgeMilliseconds`: when it creeps towards the retention period, you are about to lose data.
