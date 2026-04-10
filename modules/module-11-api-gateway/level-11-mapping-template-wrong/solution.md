# Solution

```bash
# Edit the local mission artifact first
$EDITOR mapping.json
# This edited file applies to: --rest-api-id <api-id>, --resource-id <resource-id>

# Then apply the fix
aws apigateway put-integration --rest-api-id <api-id> --resource-id <resource-id> --http-method POST --request-templates file://mapping.json
```
