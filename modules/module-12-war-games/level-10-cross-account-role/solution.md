# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: --role-name mission-role

# Then start applying the recovery steps
aws iam update-assume-role-policy --role-name mission-role --policy-document file://trust-policy.json
```
