# Debrief: a metric is not a monitor

CloudWatch collects metrics whether or not anyone is watching. Nothing happens on a bad value until an **alarm** is attached to it. An alarm evaluates one metric (or a metric-math expression) over `EvaluationPeriods` consecutive periods of `Period` seconds, applies a `Statistic`, and compares the result with `Threshold` using `ComparisonOperator`. It has exactly three states:

- `OK`: the condition is not breached.
- `ALARM`: it is breached for the required number of periods.
- `INSUFFICIENT_DATA`: not enough data to decide (a new alarm, or a metric that stopped reporting and `TreatMissingData` is `missing`).

**Actions are separate from state.** An alarm without `AlarmActions` changes state and notifies nobody. Actions run on *transitions*, not continuously: if a topic had no subscribers when the alarm fired, you will not be told again until it leaves and re-enters ALARM.

**In real life**
- Alarm on latency percentiles (p95/p99) rather than averages, which hide tail problems.
- `Period` interacts with the metric's resolution: standard metrics need multiples of 60 seconds; 10 and 30 seconds require high-resolution metrics. Short periods catch bursts but flap more.
- Use `OK` and `INSUFFICIENT_DATA` actions too, so on-call sees recovery.
- Define alarms next to the service in code, and test them: publish an out-of-range value with `put-metric-data` (as this validator does) after any change.
