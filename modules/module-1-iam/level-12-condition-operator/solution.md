# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --role-name prefix-reader-role, --policy-name prefix-reader-policy

# Then attach the corrected policy
aws iam put-role-policy   --role-name prefix-reader-role   --policy-name prefix-reader-policy   --policy-document file://policy.json
```
