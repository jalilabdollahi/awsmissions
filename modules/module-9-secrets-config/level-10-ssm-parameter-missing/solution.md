# Solution

```bash
# Edit the local mission artifact first
$EDITOR config.json
# This edited file applies to: --name /mission/config/db-host

# Then apply the fix
aws ssm put-parameter --name /mission/config/db-host --value db.local --type String
```
