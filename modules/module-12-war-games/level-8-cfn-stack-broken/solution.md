# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: --stack-name mission-stack

# Then start applying the recovery steps
aws cloudformation delete-stack --stack-name mission-stack
```
