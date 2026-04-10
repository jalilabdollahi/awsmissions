# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: --bucket mission-bucket

# Then start applying the recovery steps
aws s3api put-public-access-block --bucket mission-bucket --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```
