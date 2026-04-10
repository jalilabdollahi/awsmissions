# Solution

```bash
aws s3api put-bucket-notification-configuration   --bucket uploads-bucket   --notification-configuration file://notification.json

aws s3api put-bucket-notification-configuration   --bucket wrong-bucket   --notification-configuration '{}'
```
