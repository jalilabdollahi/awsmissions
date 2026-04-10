# Solution

```bash
# Edit the local mission artifact first
$EDITOR api.json
# This edited file applies to: --name mission-api

# Then apply the fix
aws apigateway create-rest-api --name mission-api
```
