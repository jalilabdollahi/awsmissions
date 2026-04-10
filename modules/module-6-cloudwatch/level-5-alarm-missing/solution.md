# Solution

```bash
# Edit the local mission artifact first
$EDITOR alarm.json
# This edited file applies to: AlarmName mission-error-alarm, MetricName ErrorCount

# Then apply the fix
aws cloudwatch put-metric-alarm --cli-input-json file://alarm.json
```
