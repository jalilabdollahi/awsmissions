# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --policy-name deployer-policy

# Then attach it to the user
aws iam put-user-policy   --user-name mission-deployer   --policy-name deployer-policy   --policy-document file://policy.json
```
