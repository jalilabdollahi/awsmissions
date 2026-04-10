# Solution

```bash
# Edit the local mission artifact first
$EDITOR task-definition.json
# This edited file applies to: secrets name=DB_PASSWORD, valueFrom=arn:aws:secretsmanager:us-east-1:000000000000:secret:mission-db

# Then apply the fix
aws ecs register-task-definition --cli-input-json file://task-definition.json
```
