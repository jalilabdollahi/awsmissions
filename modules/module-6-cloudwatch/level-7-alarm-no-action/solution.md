# Solution

```bash
# Edit the local mission artifact first
$EDITOR alarm.json
# This edited file applies to: AlarmActions arn:aws:sns:us-east-1:000000000000:mission-topic

# Then apply the fix
aws cloudwatch put-metric-alarm --cli-input-json file://alarm.json
```
