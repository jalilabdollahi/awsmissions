# Debrief: some design decisions are made once, at creation

DynamoDB has two kinds of secondary index and they differ in exactly this respect:

| | Global (GSI) | Local (LSI) |
|---|---|---|
| Partition key | any attribute | same as the table |
| Sort key | any attribute | a different attribute |
| Add after creation | yes | **never**, only in `create-table` |
| Capacity | own | shares the table's |
| Consistency | eventual only | strong reads possible |
| Limits | 20 per table | 5 per table, and a 10 GB cap per partition key value |

Because the LSI shares the partition with the table, it can offer strongly consistent reads and uses the table's capacity. That tight coupling is why DynamoDB wants to know about it before any data is stored. The 10 GB item-collection limit is the hidden cost: with an LSI, all items and index entries that share a partition key must fit into 10 GB, otherwise writes fail.

So the practical rule: if you are not sure you need strong consistency or the table's capacity sharing, **prefer a GSI**, which you can add and remove whenever.

Migration advice for real tables:
- Create the new table (with LSI) under a temporary name, copy items in parallel (export to S3 + import, or a parallel scan with batch writes), dual-write from the app, verify, then switch the table name in config. Avoid delete-then-recreate for production.
- Remember to carry over TTL settings, streams, PITR, tags, alarms and IAM policies. They belong to the table, not to the name.
- Scan output uses DynamoDB JSON, which `put-item --item` accepts directly, so a small script is enough for small tables.
