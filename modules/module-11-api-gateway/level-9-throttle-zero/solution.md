# Solution

```bash
# Edit the local mission artifact first
$EDITOR stage.json
# This edited file applies to: --rest-api-id <api-id>, --stage-name prod

# Then apply the fix
aws apigateway update-stage --rest-api-id <api-id> --stage-name prod --patch-operations op=replace,path=/*/*/throttling/burstLimit,value=100
```
