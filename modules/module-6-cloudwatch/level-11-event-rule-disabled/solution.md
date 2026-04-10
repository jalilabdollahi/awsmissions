# Solution

```bash
# Edit the local mission artifact first
$EDITOR rule.json
# This edited file applies to: --name mission-rule

# Then apply the fix
aws events enable-rule --name mission-rule
```
