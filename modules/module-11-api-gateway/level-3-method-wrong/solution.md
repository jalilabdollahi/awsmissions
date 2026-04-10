# Solution

```bash
# Edit the local mission artifact first
$EDITOR method.json
# This edited file applies to: --rest-api-id <api-id>, --resource-id <resource-id>

# Then apply the fix
aws apigateway put-method --rest-api-id <api-id> --resource-id <resource-id> --http-method POST --authorization-type NONE
```
