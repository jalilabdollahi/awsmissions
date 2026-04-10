# Solution

```bash
# Edit the local mission artifact first
$EDITOR policy.json
# This edited file applies to: --role-name mission-lambda-role, --policy-name mission-logs

# Then apply the fix
aws iam put-role-policy --role-name mission-lambda-role --policy-name mission-logs --policy-document file://policy.json
```
