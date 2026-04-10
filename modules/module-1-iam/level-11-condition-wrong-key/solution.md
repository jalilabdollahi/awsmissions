# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --role-name guarded-role, --policy-name guarded-policy

# Then attach the corrected policy
aws iam put-role-policy   --role-name guarded-role   --policy-name guarded-policy   --policy-document file://policy.json
```
