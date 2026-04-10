# Solution

```bash
# Edit the local mission artifact first
$EDITOR config.json
# This edited file applies to: --name /production/db/password

# Then apply the fix
aws ssm put-parameter --name /production/db/password --value secret --type SecureString
```
