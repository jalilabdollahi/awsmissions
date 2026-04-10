# Solution

```bash
# Edit the local mission artifact first
$EDITOR query.txt
# This edited file applies to: --log-group-name /aws/lambda/mission-function

# Then apply the fix
aws logs start-query --log-group-name /aws/lambda/mission-function --query-string "fields @timestamp, @message | filter @message like /ERROR/ | stats count() by bin(5m)" --start-time 0 --end-time 1
```
