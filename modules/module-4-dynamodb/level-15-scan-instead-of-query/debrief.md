# Debrief: Scan reads everything, Query reads one partition

`Scan` walks the whole table and applies `FilterExpression` **after** reading. You are billed (and throttled) for every item scanned, not for those returned, so a filter makes the result smaller but not the bill. `Query` jumps to one partition-key value and reads only the contiguous slice that matches the sort-key condition. For a table with millions of items that is the difference between 4 KB and gigabytes.

To turn a scan into a query you need an access path whose partition key is the thing you filter by with equality. If the base table's key is wrong for the question, add a **GSI** with the right key. That is why a design starts from access patterns: "shipments of region X after time Y" becomes partition key `region`, sort key `shippedAt`.

The IAM side is where many teams stumble:
- **Indexes have their own ARN**: `arn:aws:dynamodb:REGION:ACCOUNT:table/NAME/index/INDEX`. A policy for the table ARN alone does not allow queries on its indexes, and `table/NAME/*` covers both the table and all its indexes (use it deliberately).
- The action for both table and index reads is `dynamodb:Query`; only the Resource differs, so a read-only reporting role lists the table ARN and the index ARN. (The local emulator only evaluates the table ARN for index queries, real AWS evaluates the index ARN. Writing both is correct in both worlds.)
- `Scan` is dangerous to leave granted: it is the one call that can read every item. Many organisations forbid it in production roles and enforce it with an SCP or a permissions boundary.
- You can go one step further with the condition key `dynamodb:LeadingKeys` to restrict which partition keys (for example, which regions) a principal may read, and `dynamodb:Select` / `dynamodb:Attributes` to restrict returned data.

Real-world tips:
- If you must scan (exports, one-off maintenance), use parallel scan with segments, a rate limit, and prefer an export to S3 from PITR, which costs no read capacity.
- A sparse GSI (only items carrying the index key attribute are indexed) can turn "all unprocessed items" into a cheap query.
