# Debrief: AT or AFTER, one word, one duplicate

Resuming from a stored position gives you two sequence-number iterators:

- `AT_SEQUENCE_NUMBER n`: the first record returned is record `n` itself. Use it when `n` is a position you *have not* processed (for example one you remembered from `GetRecords` before handling it).
- `AFTER_SEQUENCE_NUMBER n`: the first record returned is the one after `n`. Use it when `n` is the last record you *finished*.

The rule is about what your checkpoint means. "Last processed" pairs with AFTER; "next to process" pairs with AT. The bug here was a mismatch between the two, which produces exactly one duplicate per run, small enough to survive testing and big enough for support tickets.

**Why you still need idempotency.** Even with the right iterator, Kinesis consumers are **at-least-once**: if the function crashes after billing an event but before saving the checkpoint, the next run bills it again. The ledger's `ADD times_billed 1` makes duplicates visible but not harmless. Prefer a conditional write keyed by event id (`attribute_not_exists(event_id)`) so a replay is a no-op.

**Checkpoint hygiene**
- Save the checkpoint after the side effects, never before, so a crash causes a replay and not a gap.
- Store it per shard (a checkpoint of one shard means nothing on another).
- Libraries do this for you: the KCL keeps leases and checkpoints in DynamoDB, and Lambda event source mappings track positions internally. Hand-rolled checkpointing like this is where off-by-one bugs live.
