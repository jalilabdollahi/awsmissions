# Debrief: global secondary indexes add access patterns, not tables

The base table of cartwheel-members can only answer one question efficiently: "give me member X by memberId". "Find the member with this email" would be a full scan. A **global secondary index (GSI)** is a second, automatically maintained copy of the data with a different primary key. DynamoDB keeps it in sync asynchronously after every write, which means reads from a GSI are always eventually consistent.

Key facts:
- A GSI can be added to or removed from an existing table at any time, and is backfilled from existing items. Only one GSI creation can be running per `update-table` call, and while it is `CREATING` it cannot be queried.
- Any attribute used as an index key must appear in `AttributeDefinitions` with its type.
- Items that lack the index key attribute simply do not appear in the index (a "sparse index", a useful trick for things like "only open orders").
- Index key values do not have to be unique. Email works as a partition key here only because it is nearly unique; if it were not, a sort key would be needed to tell results apart.
- A GSI has its own capacity. On a provisioned table the index needs its own `ProvisionedThroughput`; on-demand tables need nothing.
- Projection decides which attributes are copied into the index (`KEYS_ONLY`, `INCLUDE`, `ALL`). That matters later, when you are paying for storage and writes.

A query against a non-existent index name fails with "The table does not have the specified index".
