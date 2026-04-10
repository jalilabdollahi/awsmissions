# Solution

```bash
# Edit the local mission artifact first
$EDITOR integration.json
# This edited file applies to: --rest-api-id <api-id>, --resource-id <resource-id>

# Then apply the fix
aws apigateway put-integration --rest-api-id <api-id> --resource-id <resource-id> --http-method POST --type AWS_PROXY --integration-http-method POST --uri <lambda-uri>
```
