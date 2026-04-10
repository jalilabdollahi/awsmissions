# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: --bucket uploads-bucket

# Then start applying the recovery steps
aws s3api put-bucket-notification-configuration --bucket uploads-bucket --notification-configuration file://notification.json
```
