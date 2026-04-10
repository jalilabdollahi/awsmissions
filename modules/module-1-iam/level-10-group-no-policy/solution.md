# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --group-name empty-group, --policy-name empty-group-policy

# Attach the policy to the group
aws iam put-group-policy   --group-name empty-group   --policy-name empty-group-policy   --policy-document file://policy.json
```
