# Solution

```bash
# First discover the correct account ID
aws sts get-caller-identity --query Account --output text

# Edit the local file first
$EDITOR trust-policy.json
# This edited file applies to: --role-name cross-account-role

# Then apply it from this level directory
aws iam update-assume-role-policy   --role-name cross-account-role   --policy-document file://trust-policy.json
```
