# Solution

```bash
# Edit the local mission artifact first
$EDITOR task-definition.json
# This edited file applies to: image 000000000000.dkr.ecr.us-east-1.amazonaws.com/mission-app:latest

# Then apply the fix
aws ecs register-task-definition --cli-input-json file://task-definition.json
```
