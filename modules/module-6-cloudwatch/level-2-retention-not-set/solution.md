# Solution

```bash
# Edit the local mission artifact first
$EDITOR config.json
# This edited file applies to: --log-group-name /aws/lambda/mission-function

# Then apply the fix
aws logs put-retention-policy --log-group-name /aws/lambda/mission-function --retention-in-days 30
```
