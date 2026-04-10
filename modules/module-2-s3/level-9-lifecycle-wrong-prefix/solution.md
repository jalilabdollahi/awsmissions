# Solution

```bash
# Edit the local file first
$EDITOR config.json
# This edited file applies to: --bucket mission-bucket

# Then apply it from this level directory
aws s3api put-bucket-lifecycle-configuration   --bucket mission-bucket   --lifecycle-configuration file://config.json
```
