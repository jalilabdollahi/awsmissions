# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --role-name object-reader-role, --policy-name object-reader-policy

# Then apply it from this level directory
aws iam put-role-policy \
  --role-name object-reader-role \
  --policy-name object-reader-policy \
  --policy-document file://policy.json
```
