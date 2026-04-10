# Solution

```bash
# Edit the local mission artifact first
$EDITOR alarm.json
# This edited file applies to: Period 300

# Then apply the fix
aws cloudwatch put-metric-alarm --cli-input-json file://alarm.json
```
