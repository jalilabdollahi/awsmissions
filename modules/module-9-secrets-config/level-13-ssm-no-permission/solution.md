# Solution

```bash
# Edit the local mission artifact first
$EDITOR policy.json
# This edited file applies to: --role-name mission-task-role, --policy-name mission-ssm

# Then apply the fix
aws iam put-role-policy --role-name mission-task-role --policy-name mission-ssm --policy-document file://policy.json
```
