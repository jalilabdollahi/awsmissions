# Debrief: the key schema is the query API

A DynamoDB table is defined by its primary key and almost nothing else. The **partition key** decides where an item lives; the optional **sort key** orders items inside that partition and unlocks range queries (`BETWEEN`, `>`, `begins_with`, newest-first with `ScanIndexForward=false`).

Harvest Hub's access pattern was "all orders of one farm, in time order". That maps exactly to partition key `farmId` + sort key `orderedAt`. Only the key attributes appear in `--attribute-definitions`; every other attribute is schemaless.

Things to remember:
- The key schema of a table can never be changed after creation. Decide it from your access patterns first.
- An item is identified by its full primary key. The same farmId + orderedAt twice overwrites; if two orders can arrive in the same second, put a unique suffix in the sort key (for example `orderedAt#orderId`).
- On-demand billing (`PAY_PER_REQUEST`) is the safest default for new tables with unknown traffic.
- When infrastructure is deployed "somewhere new", `list-tables` on the right account and region is always step one. Near-identical names (`harvest-order` vs `harvest-orders`) are a classic trap.
