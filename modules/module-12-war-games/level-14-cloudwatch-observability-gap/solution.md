# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: --log-group-name /aws/lambda/mission-function

# Then start applying the recovery steps
aws logs create-log-group --log-group-name /aws/lambda/mission-function
```
