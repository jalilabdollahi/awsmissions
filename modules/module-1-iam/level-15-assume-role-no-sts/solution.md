# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --policy-name switcher-policy

# Then attach it to the user
aws iam put-user-policy   --user-name switcher-user   --policy-name switcher-policy   --policy-document file://policy.json
```
