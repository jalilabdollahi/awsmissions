# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --policy-name path-check-policy

# Then attach the corrected policy to the user
aws iam put-user-policy   --user-name mission-user   --policy-name path-check-policy   --policy-document file://policy.json
```
