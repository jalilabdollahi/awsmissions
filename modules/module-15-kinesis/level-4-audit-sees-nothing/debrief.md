# Debrief: where does your iterator start?

Reading a Kinesis shard always begins with `GetShardIterator`, and the **iterator type** decides which records you will ever see:

| Type | Starts at | Typical use |
|---|---|---|
| `TRIM_HORIZON` | the oldest record still retained | batch jobs, audits, a new consumer that must see everything |
| `LATEST` | just after the newest record | a live tail ("what is happening right now") |
| `AT_TIMESTAMP` | the first record at or after a time | replay from an incident |
| `AT_SEQUENCE_NUMBER` | exactly this record | resume, including the record itself |
| `AFTER_SEQUENCE_NUMBER` | the record after this one | resume without repeating it |

`LATEST` is a silent trap for batch work: a consumer that creates its iterator and immediately calls `GetRecords` gets an empty page and a perfectly healthy 200. Nothing fails, which is why the audit looked fine for months.

**Also worth knowing**
- An empty page does **not** mean the end of the shard. Keep following `NextShardIterator`; `MillisBehindLatest == 0` says you have caught up.
- An iterator is only valid for 5 minutes, and each shard allows 5 `GetRecords` calls per second shared by all classic consumers.
- Libraries like the KCL and Lambda event source mappings hide this choice behind a *starting position* (`TRIM_HORIZON`, `LATEST`, `AT_TIMESTAMP`). Pick it deliberately when you create the consumer; on Lambda it cannot be changed afterwards.
