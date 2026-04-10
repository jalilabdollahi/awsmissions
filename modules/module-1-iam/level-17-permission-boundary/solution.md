# Solution

```bash
# Edit the local file first
$EDITOR policy.json
# This edited file applies to: --policy-name s3-read-boundary

# Create a replacement boundary policy
aws iam create-policy   --policy-name s3-read-boundary   --policy-document file://policy.json

# Then attach the new boundary to the role
aws iam put-role-permissions-boundary   --role-name bounded-reader-role   --permissions-boundary arn:aws:iam::000000000000:policy/s3-read-boundary
```
