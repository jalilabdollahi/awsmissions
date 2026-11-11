# Debrief: PutItem is an upsert on the full primary key

`PutItem` never fails because an item "already exists"; it replaces whatever has the same primary key. With a hash-only key, `ticketId` alone identifies the item, so a second event for T-1001 silently overwrote the first. No error, no warning, just missing history. That is why Fixline engineers saw "no failed writes".

A **sort key** makes the primary key composite: the pair (ticketId, eventAt) is unique, and all items sharing a partition key are stored together, sorted by the sort key. That gives you:
- one-to-many modelling (a ticket has many events),
- cheap, ordered range reads (`eventAt BETWEEN`, `>=`, `begins_with`),
- newest-first with `--no-scan-index-forward`.

ISO-8601 timestamps sort correctly as strings, which is why they make good sort keys.

Real-world tips:
- If two events can share the same timestamp, append a unique id: `2026-03-02T08:05:00Z#evt-81`.
- The sort key cannot be added later, so ask "is this one-to-many?" at design time.
- If you suspect silent overwrites, enable DynamoDB Streams or CloudTrail data events to see MODIFY records where you expected INSERT.
