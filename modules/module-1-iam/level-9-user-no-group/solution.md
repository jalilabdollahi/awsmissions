# Solution

```bash
# Create the missing group
aws iam create-group --group-name readers-group

# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --group-name readers-group, --policy-name readers-policy

# Attach the policy to the group
aws iam put-group-policy   --group-name readers-group   --policy-name readers-policy   --policy-document file://policy.json

# Add the user to the group
aws iam add-user-to-group   --user-name orphan-user   --group-name readers-group
```
