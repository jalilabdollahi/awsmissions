# Solution

```bash
# Edit the local mission artifact first
$EDITOR task-definition.json
# This edited file applies to: environment name=APP_MODE, value=production

# Then apply the fix
aws ecs register-task-definition --cli-input-json file://task-definition.json
```
