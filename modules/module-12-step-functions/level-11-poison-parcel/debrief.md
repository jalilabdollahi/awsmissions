# Debrief: design Map states for the bad item

A Map state runs its processor once per array item, usually concurrently (`MaxConcurrency`). Two ideas matter in practice.

**What the iteration sees.** An iteration's input is not "the parent's input plus the item". By default it is only the item. `ItemSelector` (the successor of the older `Parameters` field in a Map) builds the exact document each iteration receives. In it, `$` is the Map's input and `$$.Map.Item.Value` / `$$.Map.Item.Index` come from the context object. If the iteration needs a batch id, a tenant, or a feature flag, copy it in here. Anything missing produces `States.Runtime` path errors, one per item.

**What a failure means.** By default one failed iteration fails the whole Map, and the other iterations are stopped. For batch work that is rarely what the business wants. Your options:

1. A `Catch` (and `Retry`) *inside* the iteration, to handle the known bad cases explicitly. The item gets a different outcome (quarantine, dead-letter queue, a failed-items record) and the Map result stays complete. This is what this mission asks for.
2. `ToleratedFailurePercentage` / `ToleratedFailureCount` on the Map: the batch passes if "few enough" items fail. Failures are counted but not routed anywhere, so use it only with a separate record of what failed.
3. For very large datasets, the Distributed Map mode reads items from S3 and writes a result manifest with the failed ones listed.

**In real life**
- Quarantine, do not drop. A poison message that disappears is a support ticket in six weeks.
- Keep the error object (`ResultPath: "$.error"`) so the quarantine record tells a human what went wrong.
- An inline Map is limited to 40 concurrent iterations and the 256 KiB state payload; larger arrays need Distributed Map.
