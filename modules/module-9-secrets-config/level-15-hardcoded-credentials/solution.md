# Solution

```bash
# Edit the local mission artifact first
$EDITOR config.json
# This edited file applies to: --function-name mission-function

# Then apply the fix
aws lambda update-function-configuration --function-name mission-function --environment Variables={}
```
