# Solution

```bash
# Edit the local mission artifact first
$EDITOR policy.json
# This edited file applies to: --role-name mission-role, --policy-name mission-secret

# Then apply the fix
aws iam put-role-policy --role-name mission-role --policy-name mission-secret --policy-document file://policy.json
```
