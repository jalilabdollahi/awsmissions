# Solution

```bash
# Edit the local mission artifact first
$EDITOR task-definition.json
# This edited file applies to: containerPort 80

# Then apply the fix
aws ecs register-task-definition --cli-input-json file://task-definition.json
```
