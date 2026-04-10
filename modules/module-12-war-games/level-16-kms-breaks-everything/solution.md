# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: enable key

# Then start applying the recovery steps
aws kms enable-key --key-id <key-id>
```
