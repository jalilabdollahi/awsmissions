# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: add execution role

# Then start applying the recovery steps
aws ecs register-task-definition --cli-input-json file://task-definition.json
```
