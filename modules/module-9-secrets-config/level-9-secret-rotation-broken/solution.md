# Solution

```bash
# Edit the local mission artifact first
$EDITOR config.json
# This edited file applies to: --secret-id mission/db-password

# Then apply the fix
aws secretsmanager rotate-secret --secret-id mission/db-password --rotation-lambda-arn arn:aws:lambda:us-east-1:000000000000:function:rotation-function
```
