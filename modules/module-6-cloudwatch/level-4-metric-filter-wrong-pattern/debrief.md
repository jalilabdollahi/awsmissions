# Debrief: logs become metrics through patterns

A **metric filter** scans each new log event in a group and, on a match, publishes a value (here a count of 1) to a CloudWatch metric. This is how you build alarms on things your application only logs: errors, failed logins, slow queries.

**Pattern rules to remember**
- A bare term or a quoted string (`ERROR`, `"ERROR"`) matches events containing that text. It is **case-sensitive**, so `"Error"` does not match `ERROR`.
- Several terms are ANDed (`ERROR timeout`); `?ERROR ?WARN` means ERROR *or* WARN; `-term` excludes.
- For structured logs use JSON patterns (`{ $.level = "ERROR" }`) or space-delimited patterns (`[ts, level=ERROR, ...]`), which also let you pull a numeric field out as the metric value.
- Filters only see events ingested **after** they are created; they never back-fill history.

**Why it fails silently.** A filter that matches nothing produces no datapoints, so the metric looks flat or empty. Charts and alarms (with missing data treated as "not breaching") look healthy while the system is failing.

**In real life**
- Develop patterns with `aws logs test-metric-filter` or the console's *Test pattern* box before you attach them.
- Set a `defaultValue` of 0 so the metric reports zeros during quiet periods, which keeps alarms from sitting in `INSUFFICIENT_DATA`.
- Alarm on the *absence* of data for critical filters, so a broken pattern is itself noticed.
