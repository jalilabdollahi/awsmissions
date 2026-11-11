# Debrief: two halves make an S3 trigger

For S3 to run a Lambda function, two independent things must exist:

1. **A permission on the function** (its resource-based policy) that lets `s3.amazonaws.com` invoke it, scoped to the bucket with `SourceArn` (and `SourceAccount`, to stop a same-named bucket in another account from calling you: the confused-deputy problem).
2. **A notification configuration on the bucket** that names the events, the target and optional filters.

Here (1) was done and (2) was missing, so the function was healthy and entirely idle. With no trigger there is no error anywhere either: S3 does not complain about events nobody asked for.

**Filters matter as much as the trigger.** A filter rule matches on the object key's `prefix` and/or `suffix`. Without them *every* upload invokes the function, including the multi-gigabyte scans. Two filter rules on the same configuration are ANDed (prefix and suffix must both match). Overlapping prefix filters across configurations on the same bucket and event type are rejected by S3.

**Events delivered at least once.** S3 can deliver an event twice, and in no guaranteed order, so the indexer writes with `put_item` keyed by object key (idempotent). Also remember object keys arrive URL-encoded (`unquote_plus`).

**In real life**
- The notification API *replaces* the whole configuration: always fetch the current one first or you will delete other triggers.
- Use EventBridge notifications on the bucket if you need richer filtering, multiple consumers or replay.
- Never write results back into the bucket prefix that triggers the function, or you build an infinite loop.
