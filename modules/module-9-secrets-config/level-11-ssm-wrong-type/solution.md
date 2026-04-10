# Solution

```bash
# Edit the local mission artifact first
$EDITOR config.json
# This edited file applies to: --name /mission/config/api-key

# Then apply the fix
aws ssm put-parameter --name /mission/config/api-key --value secret --type SecureString --overwrite
```
