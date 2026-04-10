# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: fix metric pattern

# Then start applying the recovery steps
aws cloudwatch put-metric-alarm --cli-input-json file://alarm.json
```
