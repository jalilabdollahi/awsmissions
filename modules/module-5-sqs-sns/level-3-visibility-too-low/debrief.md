# Debrief: the visibility timeout is a lease

SQS has no "lock". When a consumer receives a message, the message stays in the queue but is hidden for the **visibility timeout** (default 30 seconds, maximum 12 hours). The consumer must delete it before the lease runs out. If it does not, because it crashed or because it was too slow, the message becomes visible and is delivered again. That is the at-least-once guarantee at work, and it is also why labels printed twice here.

**Choosing a value**
- Too low: duplicates while healthy workers are still busy (this level).
- Too high: after a worker crash the message is stuck for the whole timeout, so retries are slow and a backlog builds up.
- A good rule is 6 times the average processing time, or the worst case plus headroom.

**In real life**
- Workers with variable run times can call `ChangeMessageVisibility` to extend the lease while they work (a heartbeat), so the queue-level value can stay small.
- For Lambda consumers, set the queue timeout to at least 6 times the function timeout.
- Make consumers idempotent anyway. A lease reduces duplicates; it never eliminates them.
