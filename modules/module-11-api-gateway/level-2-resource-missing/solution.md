# Solution

```bash
# Edit the local mission artifact first
$EDITOR api.json
# This edited file applies to: --rest-api-id <api-id>, --path-part items

# Then apply the fix
aws apigateway create-resource --rest-api-id <api-id> --parent-id <root-id> --path-part items
```
