# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --role-name conflicted-reader-role, --policy-name conflicting-policy

# Re-apply the conflicting policy so it no longer denies access
aws iam put-role-policy   --role-name conflicted-reader-role   --policy-name conflicting-policy   --policy-document file://policy.json
```
