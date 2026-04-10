# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --role-name vault-reader-role, --policy-name vault-reader-policy

# Then apply it from this level directory
aws iam put-role-policy \
  --role-name vault-reader-role \
  --policy-name vault-reader-policy \
  --policy-document file://policy.json
```
