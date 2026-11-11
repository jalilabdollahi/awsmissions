# Debrief: an index is only as useful as its key

The index was called `sku-index`, but its partition key was `aisle`. DynamoDB does not care about names: a query on an index must supply an equality condition on that index's partition key, and the error you saw (`Query condition missed key schema element: aisle`) says exactly which attribute it wanted. A name is not a contract; the KeySchema is.

How to repair a GSI:
- GSI key schemas are immutable, but unlike the table's own key you can delete and re-create a GSI at any time. Nothing in the base table is touched, and the new index is backfilled from the existing items.
- While the index is being re-created, queries against it fail or return partial data. In production, create the corrected index under a new name first, switch the application, and only then drop the old one.
- The index sort key (`qty` here) makes "SKU X with at least N units" a single efficient range read. Without it you would query by SKU and filter in application code, paying to read every bin of that SKU.

Real-world tips:
- Describe every index in IaC next to the access pattern it serves ("picker: bins by SKU, qty desc").
- Index-key attributes must be declared in `AttributeDefinitions`, but the declaration only describes types. It does not say which index uses them.
- A bug like this tends to hide behind a green deployment because index creation succeeds with any attribute. Add one integration test per access pattern.
