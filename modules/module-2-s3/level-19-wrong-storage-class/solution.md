# Solution

```bash
aws s3api copy-object   --bucket mission-bucket   --key hot-data.txt   --copy-source mission-bucket/hot-data.txt   --storage-class STANDARD   --metadata-directive COPY
```
