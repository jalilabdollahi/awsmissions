# Solution

```bash
# Edit the local mission artifact first
$EDITOR config.json
# This edited file applies to: --name mission/db-password

# Then apply the fix
aws secretsmanager create-secret --name mission/db-password --secret-string "abc123"
```
