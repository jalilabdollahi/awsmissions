# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: --secret-id mission-secret

# Then start applying the recovery steps
aws secretsmanager rotate-secret --secret-id mission-secret
```
