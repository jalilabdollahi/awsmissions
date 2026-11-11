# Debrief: PM-77, "we found out from Twitter"

## Root causes
| Link | What was wrong | Why nobody noticed |
|---|---|---|
| Metric filter | Pattern `"level=FATAL"` copied from another service | The filter existed and had a metric, so dashboards showed "0 errors" instead of "no data" |
| Alarm | `LessThanThreshold` copied from a throughput alarm | With `treatMissingData=notBreaching` it sat happily in OK |
| Action | `AlarmActions` empty | Alarms with no action still change state, so the console looked fine |

## Timeline
- Quarter start: monitoring "rebuilt" by cloning a template from the billing team.
- Sat 02:10 UTC: ledger lock contention starts; 40% of batches fail, all logged as `level=ERROR`.
- Sat 05:50 UTC: a merchant tweets; humans notice.
- Postmortem finding: the alarm was never tested end to end.

## How CloudWatch works here
Metric filters only emit data points for events ingested after the filter exists and only when the pattern matches. Alarms compare a statistic over each period with the threshold; the SNS action fires on a *state transition*, not on every evaluation. That is why the validator resets the alarm to OK before it sends the burst.

## Lessons
- Test alerts like you test code: inject a synthetic failure and watch the page arrive. `aws logs test-metric-filter` and `aws cloudwatch set-alarm-state` make this cheap.
- Treat monitoring as code reviewed in PRs; "cloned from another team" is not a review.
- Never fix a silent alarm by loosening it into noise. Alert fatigue is the next outage.
- Consider a second alarm on "no data at all" (`treatMissingData=breaching` or a heartbeat) so a dead filter is itself visible.
