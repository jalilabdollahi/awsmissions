# Solution

```bash
# Edit the local mission artifact first
$EDITOR secret.json
# This edited file applies to: --secret-id mission/db-password

# Then apply the fix
aws secretsmanager put-secret-value --secret-id mission/db-password --secret-string file://secret.json
```
