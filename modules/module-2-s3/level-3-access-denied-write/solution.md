# Solution

```bash
# Edit the local file first
$EDITOR bucket-policy.json
# This edited file applies to: --bucket mission-bucket

# Then apply it from this level directory
aws s3api put-bucket-policy   --bucket mission-bucket   --policy file://bucket-policy.json
```
