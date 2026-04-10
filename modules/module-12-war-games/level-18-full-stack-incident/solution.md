# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: reconcile drift

# Then start applying the recovery steps
aws cloudwatch enable-alarm-actions --alarm-names mission-alarm
```
