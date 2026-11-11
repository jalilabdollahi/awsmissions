# Debrief: ORBIT-1893, the leaderboard that stopped moving

## Root causes
1. Streams were toggled off and on again. The re-enable used `KEYS_ONLY`, so records carried no `NewImage`.
2. The event source mapping stayed attached to the original stream ARN. Each time a stream is enabled it gets a new ARN, and the old one is dead.
3. The function pointed at `orbit-leaderboards` (plural), a name from a design doc.
4. The role's policy listed `PutItem` where the code calls `UpdateItem`.

## Timeline
- Tue 21:40 streams switched off to save cost; the Lambda trigger was the consumer.
- Tue 22:05 switched back on by someone doing a rollback; default view type chosen: KEYS_ONLY.
- Tue 22:30 config tidy-up (3) and security template applied (4).
- Wed 08:15 support reports a frozen leaderboard; ORBIT-1893.

## Why it was hard
Each fault yields a different silence. No stream means no events. A stale mapping means events with nobody listening. A bad table name or a missing permission gives errors, but they only appear in the function's own logs, never at the source. Stream consumers usually fail without any user-visible error.

## Lessons
- Streams are stateful infrastructure. Treat "disable/enable" like a deployment: re-point every consumer afterwards.
- Alarm on the `IteratorAge` metric and on Lambda `Errors`. A stream whose consumer is gone grows an invisible backlog until records expire after 24 hours.
- Choose view types deliberately. `NEW_AND_OLD_IMAGES` costs more bandwidth but spares you from a second incident when a consumer needs the old value.
- Test consumers by invoking them with a recorded event; it takes seconds and isolates code and permission errors from plumbing errors.
