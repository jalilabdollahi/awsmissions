# Debrief: PM-2026-31, 47 minutes of green dashboards

## Root causes
| Link | Fault | Why it survived |
|---|---|---|
| Filter location | Attached to `/aws/lambda/tf-checkout-fn-old` | The old group still existed, so the filter looked healthy in the console |
| Filter pattern | `$.severity` from the draft spec, not `$.level` | JSON filters never error on unknown fields; they just don't match |
| Metric identity | Namespace `TF/Checkouts` vs `TF/Checkout` | A metric with a different namespace is a different metric. The alarm saw no data and (with `notBreaching`) stayed OK |
| Notification | Alarm copied from staging, pointing at a sandbox topic | SNS publish to a topic with no subscribers succeeds |

## Timeline
- Spring: function renamed; filter never moved.
- 2026-11-04 19:12: payment provider fails; one order in three errors out.
- 19:59: provider recovers by itself.
- 2026-11-05: postmortem finds that no layer of the monitoring had ever fired.

## What the pieces really do
A metric filter is evaluated on log events as they arrive in one specific log group; it creates data points in a custom metric identified by namespace plus name plus dimensions. Alarms reference that identity by exact string match. Every hand-off tolerates a mistake silently: filters match nothing, alarms read missing data, and SNS drops messages with no subscriber.

## Lessons
- Prove alerts end to end with a synthetic failure; that is the only test that exercises all four hand-offs.
- Treat "treat missing data as not breaching" as a decision, not a default. Add a second alarm that fires when the metric has no data at all.
- Define metric namespace and name once (IaC variable) and use it for both filter and alarm.
- Delete stale log groups, filters and topics after renames.
