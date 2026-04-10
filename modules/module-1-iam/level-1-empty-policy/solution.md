# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --role-name report-reader-role, --policy-name report-reader-policy

# Then apply it from this level directory
aws iam put-role-policy \
  --role-name report-reader-role \
  --policy-name report-reader-policy \
  --policy-document file://policy.json
```
