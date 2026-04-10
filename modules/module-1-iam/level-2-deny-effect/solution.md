# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --role-name uploader-role, --policy-name uploader-policy

# Then apply it from this level directory
aws iam put-role-policy \
  --role-name uploader-role \
  --policy-name uploader-policy \
  --policy-document file://policy.json
```
