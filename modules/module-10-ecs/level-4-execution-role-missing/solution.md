# Solution

```bash
# Edit the local mission artifact first
$EDITOR task-definition.json
# This edited file applies to: executionRoleArn arn:aws:iam::000000000000:role/ecsTaskExecutionRole

# Then apply the fix
aws ecs register-task-definition --cli-input-json file://task-definition.json
```
