# Solution

```bash
# Edit the local mission artifact first
$EDITOR policy.json
# This edited file applies to: --policy-name default

# Then apply the fix
aws kms put-key-policy --key-id <key-id> --policy-name default --policy file://policy.json
```
