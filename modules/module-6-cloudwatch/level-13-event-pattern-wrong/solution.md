# Solution

```bash
# Edit the local mission artifact first
$EDITOR pattern.json
# This edited file applies to: --name mission-rule

# Then apply the fix
aws events put-rule --name mission-rule --event-pattern file://pattern.json
```
