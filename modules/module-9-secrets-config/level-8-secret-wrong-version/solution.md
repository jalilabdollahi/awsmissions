# Solution

```bash
# Edit the local mission artifact first
$EDITOR config.json
# This edited file applies to: --secret-id mission/db-password

# Then apply the fix
aws secretsmanager get-secret-value --secret-id mission/db-password --version-stage AWSCURRENT
```
