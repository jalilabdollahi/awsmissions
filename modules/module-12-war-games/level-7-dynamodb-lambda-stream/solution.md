# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: --function-name mission-function

# Then start applying the recovery steps
aws lambda create-event-source-mapping --function-name mission-function --event-source-arn <stream-arn>
```
