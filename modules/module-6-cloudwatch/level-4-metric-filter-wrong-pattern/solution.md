# Solution

A metric filter pattern is **case-sensitive**. The filter looks for the term `"Error"`, but the service writes `ERROR`, so no line ever matches.

1. Compare the pattern with a real log line:

```bash
aws logs describe-metric-filters --log-group-name /ledgerbox/payments
aws logs filter-log-events --log-group-name /ledgerbox/payments --max-items 5
aws logs test-metric-filter --filter-pattern '"Error"' --log-event-messages "2026-11-11T10:02:11Z ERROR gateway timeout"
```

2. Change `filterPattern` in `filter.json` to `"\"ERROR\""` (the quotes inside make it an exact term) and re-apply. `put-metric-filter` with an existing filter name replaces it:

```bash
aws logs put-metric-filter --cli-input-json file://filter.json
```

3. Run `check`. The validator logs three ERROR lines among other lines (one of them an INFO line containing "0 errors") and expects the metric to increase by exactly 3.
