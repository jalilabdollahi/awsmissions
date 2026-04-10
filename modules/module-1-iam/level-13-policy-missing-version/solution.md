# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --role-name home-reader-role, --policy-name home-reader-policy

# Then attach the corrected policy
aws iam put-role-policy   --role-name home-reader-role   --policy-name home-reader-policy   --policy-document file://policy.json
```
