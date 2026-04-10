# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: --queue-url <queue-url>

# Then start applying the recovery steps
aws sqs set-queue-attributes --queue-url <queue-url> --attributes VisibilityTimeout=60
```
