# Solution

```bash
# Edit the local mission artifact first
$EDITOR config.json
# This edited file applies to: useAlias True

# Then apply the fix
aws kms describe-key --key-id alias/mission-key
```
