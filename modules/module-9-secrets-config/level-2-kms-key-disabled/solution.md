# Solution

```bash
# Edit the local mission artifact first
$EDITOR config.json
# This edited file applies to: enabled True

# Then apply the fix
aws kms enable-key --key-id <key-id>
```
