# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --policy-name lean-reader-policy

# Create a compact managed policy
aws iam create-policy   --policy-name lean-reader-policy   --policy-document file://policy.json

# Then attach it to the role
aws iam attach-role-policy   --role-name bloated-role   --policy-arn arn:aws:iam::000000000000:policy/lean-reader-policy
```
