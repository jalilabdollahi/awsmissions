# Solution

```bash
# Edit the local mission artifact first
$EDITOR config.json
# This edited file applies to: --log-group-name /aws/lambda/mission-function, --log-stream-name mission-stream

# Then apply the fix
aws logs create-log-stream --log-group-name /aws/lambda/mission-function --log-stream-name mission-stream
```
