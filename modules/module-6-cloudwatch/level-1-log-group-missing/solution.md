# Solution

```bash
# Edit the local mission artifact first
$EDITOR config.json
# This edited file applies to: --log-group-name /aws/lambda/mission-function

# Then apply the fix
aws logs create-log-group --log-group-name /aws/lambda/mission-function
```
