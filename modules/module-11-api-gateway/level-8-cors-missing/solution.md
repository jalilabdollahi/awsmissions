# Solution

```bash
# Edit the local mission artifact first
$EDITOR cors.json
# This edited file applies to: --rest-api-id <api-id>, --resource-id <resource-id>

# Then apply the fix
aws apigateway put-method-response --rest-api-id <api-id> --resource-id <resource-id> --http-method OPTIONS --status-code 200
```
