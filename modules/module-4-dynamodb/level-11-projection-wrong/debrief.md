# Debrief: a projection is a storage and write-cost decision

An index stores a copy of items, and the **projection** decides how much of each item gets copied:

- `KEYS_ONLY`: table keys + index keys. Smallest and cheapest; you need a second `GetItem` per hit to fetch the rest.
- `INCLUDE`: keys plus a list of attributes you name (up to 100 across all indexes of a table).
- `ALL`: the whole item. Fast reads, but every write to the table rewrites the full item into the index too, and you pay storage twice.

Querying an index for an attribute that isn't projected does not error on a GSI: the attribute just isn't there (for an LSI, DynamoDB fetches it from the table at extra read cost). That is why Shelfwise shows blank cards instead of an error.

How to choose:
1. List the attributes the access pattern actually returns.
2. Project exactly those with `INCLUDE`. Large or rarely used attributes (blurbs, blobs, JSON) stay out.
3. If the pattern needs almost everything and items are small, `ALL` is fine.
4. Writes only touch an index when an indexed or projected attribute changes. Projecting a frequently-updated attribute (view counters) into an index multiplies write cost.

Because the projection is fixed at index creation, changing it means delete + create (a backfill from the table). Create the replacement under a new name first in production, shift readers, then delete the old one.
