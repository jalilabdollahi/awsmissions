# Solution

```bash
# Edit the local mission artifact first
$EDITOR config.json
# This edited file applies to: --alias-name alias/production-key, --target-key-id <key-id>

# Then apply the fix
aws kms create-alias --alias-name alias/production-key --target-key-id <key-id>
```
