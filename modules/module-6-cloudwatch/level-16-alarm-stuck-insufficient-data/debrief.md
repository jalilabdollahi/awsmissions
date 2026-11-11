# Debrief: what does silence mean?

For every period CloudWatch either has datapoints or it does not. `TreatMissingData` decides what a period without data counts as:

| Setting | Missing period is treated as | Good for |
|---|---|---|
| `missing` (default) | skipped; alarm may go to INSUFFICIENT_DATA | metrics that should always report |
| `notBreaching` | within threshold (healthy) | event-style metrics that only exist on failure |
| `breaching` | beyond threshold (bad) | heartbeats: silence means the system died |
| `ignore` | keeps the current state | flaky reporters |

The right answer comes from the metric's *semantics*. A failure counter that only reports on failure should be `notBreaching`. A heartbeat or "hosts reporting" metric should be `breaching`, because silence is the failure.

**Other tips**
- Better still, make the producer publish an explicit 0 on success. Then the alarm needs no special handling and the graph shows a continuous line.
- INSUFFICIENT_DATA also appears for brand-new alarms and when a metric's dimensions change, so alarm on it with care.
- Metric filters can emit zeros with `defaultValue: 0` for the same purpose.

**In real life**
- Dashboards and status boards should show grey as an error state of the *monitoring*, and someone should own removing every long-grey alarm.
