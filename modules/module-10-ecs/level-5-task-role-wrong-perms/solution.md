# Solution

```bash
# Edit the local mission artifact first
$EDITOR policy.json
# This edited file applies to: --role-name mission-task-role, --policy-name mission-s3

# Then apply the fix
aws iam put-role-policy --role-name mission-task-role --policy-name mission-s3 --policy-document file://policy.json
```
