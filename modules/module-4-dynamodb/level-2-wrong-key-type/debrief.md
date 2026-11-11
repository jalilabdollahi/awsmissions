# Debrief: key types are part of the contract

Every key attribute has a declared scalar type: `S` (string), `N` (number) or `B` (binary). DynamoDB rejects any write whose key value has a different type, with `Type mismatch for key recipientId expected: N actual: S`. Non-key attributes have no declared type at all, which is why people sometimes assume keys are equally flexible.

Why you cannot fix it in place: the key schema and key types of a table (and of a local secondary index) are immutable. The partition key is hashed to pick a storage partition, so changing its type would mean relocating every item. The only path is: create a new table, copy data over, switch the application. With a populated table you would use a scan + batch-write loop, an export/import, or AWS Database Migration Service.

Deletion protection is the guardrail that made this slightly more annoying, and that is its job. It makes `DeleteTable` fail until someone deliberately turns it off. Production tables should have it on, whether the table was created by hand or by IaC.

Real-world tips:
- Identity providers hand out UUIDs, emails, ULIDs: all strings. Use `S` unless you really do arithmetic on the key.
- A numeric key that looks like an id (phone numbers, ZIP codes) loses leading zeros. Prefer strings.
- Test the first write with a realistic id, not `1`.
