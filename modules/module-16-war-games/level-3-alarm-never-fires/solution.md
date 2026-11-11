# Solution

1. **Metric filter.** The pattern was `"level=FATAL"`; the API logs `level=ERROR`. Re-run `put-metric-filter` with `"level=ERROR"` (same filter name, so it is replaced). Using an empty pattern would count INFO lines too and make the alarm meaningless.
2. **Alarm operator.** `LessThanThreshold` with threshold 5 means "alarm when fewer than five errors". Use `GreaterThanOrEqualToThreshold`.
3. **Alarm action.** `AlarmActions` was empty. Add `arn:aws:sns:us-east-1:000000000000:kp-oncall-pager`. The topic is already subscribed to the pager queue.

Steps 2 and 3 are the same `aws cloudwatch put-metric-alarm` call, because it replaces the full definition.

`check` first uses `test-metric-filter` and the alarm definition to triage, then really logs seven ERROR lines and one INFO line, resets the alarm to OK and waits for a notification to arrive on `kp-pager-inbox`.
