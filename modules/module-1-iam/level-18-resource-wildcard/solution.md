# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --role-name object-scope-role, --policy-name object-scope-policy

# Then attach the corrected policy
aws iam put-role-policy   --role-name object-scope-role   --policy-name object-scope-policy   --policy-document file://policy.json
```
