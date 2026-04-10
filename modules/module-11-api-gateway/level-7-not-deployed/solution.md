# Solution

```bash
# Edit the local mission artifact first
$EDITOR stage.json
# This edited file applies to: --rest-api-id <api-id>, --stage-name prod

# Then apply the fix
aws apigateway create-deployment --rest-api-id <api-id> --stage-name prod
```
