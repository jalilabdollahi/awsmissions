# Debrief: which direction is "bad"?

The four basic operators are `GreaterThanThreshold`, `GreaterThanOrEqualToThreshold`, `LessThanThreshold` and `LessThanOrEqualToThreshold`. The right one depends on the *meaning* of the metric:

| Metric | Bad direction | Operator |
|---|---|---|
| CPU, latency, error count, queue age | up | `GreaterThan...` |
| Free disk space, healthy host count, request throughput, cache hit rate | down | `LessThan...` |

An inverted alarm is worse than no alarm: it generates noise when things are healthy, teaches people to ignore it, and is silent in the real incident. The reason text on the alarm (`StateReason`) is the fastest clue: it prints the actual datapoint and the comparison that was applied.

**Related traps**
- `<` versus `<=` at the exact threshold value matters for discrete metrics such as host counts.
- For "low" alarms, missing data usually means *breaching* (a dead host stops reporting), so consider `TreatMissingData: breaching` for them.
- Use a statistic that matches the direction: `Minimum` for "lowest free space", `Maximum` for "highest latency".

**In real life**
- Name alarms after the symptom ("volume-low-space"), so that reading the name and the operator together immediately shows an inconsistency.
- Every alarm should have been seen to fire at least once in a test, in both directions.
