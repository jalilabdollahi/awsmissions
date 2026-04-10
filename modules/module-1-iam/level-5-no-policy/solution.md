# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --role-name lambda-basic-role, --policy-name lambda-basic-policy

# Then attach it as an inline policy
aws iam put-role-policy \
  --role-name lambda-basic-role \
  --policy-name lambda-basic-policy \
  --policy-document file://policy.json
```
