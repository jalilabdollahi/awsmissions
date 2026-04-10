# Solution

```bash
# Edit the local file first
$EDITOR config.json
# This edited file applies to: --bucket lock-bucket

# Then apply it to the protected object
aws s3api put-object-retention   --bucket lock-bucket   --key protected.txt   --retention file://config.json   --bypass-governance-retention
```
