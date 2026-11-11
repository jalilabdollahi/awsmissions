# Debrief: TT-5530, tickets sold but never fulfilled

## Root causes
1. SNS filter policy matched the pre-rename event name, so sales were dropped at the topic. SNS reports a successful publish even when no subscription matches, which is why checkout saw no errors.
2. The subscription delivered the SNS envelope rather than the raw body. Messages reached the queue but the function threw on every record, so they bounced back until retention expired.
3. The event source mapping was disabled. Nothing consumed the queue.
4. Reserved concurrency of 0 throttles every invocation: a deliberate "off switch" that was left behind after the tidy-up.

## Timeline
- Tue 09:00 release renames the event; filter not updated (1).
- Tue 13:00 subscription recreated for the new topic with default delivery (2).
- Tue 16:30 "pre-freeze tidy" disables the mapping (3) and parks the function at concurrency 0 (4).
- Wed 11:05 support raises TT-5530.

## Why it took so long
Each fault alone hides the others: with the filter broken nothing reaches the queue, so nobody sees the envelope problem; with the mapping off nobody sees the throttling. Layered pipelines fail silently at every hop, and a "publish succeeded" log line says nothing about the other end.

## Lessons
- Instrument the hops: queue depth, `NumberOfMessagesSent` per subscription, Lambda throttles, and an alarm on the oldest message age.
- Keep a DLQ on both the subscription and the queue. A poison envelope should end up somewhere visible.
- Treat renaming an event as a contract change: update filter policies in the same change.
- Reserved concurrency 0 and a disabled mapping are legitimate kill switches. Give them a ticket and an expiry.
