# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: --topic-arn <topic>

# Then start applying the recovery steps
aws sns subscribe --topic-arn <topic> --protocol sqs --notification-endpoint <queue-arn>
```
