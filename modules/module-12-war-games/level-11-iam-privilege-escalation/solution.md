# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: --role-name mission-role, --policy-name restricted

# Then start applying the recovery steps
aws iam put-role-policy --role-name mission-role --policy-name restricted --policy-document file://policy.json
```
