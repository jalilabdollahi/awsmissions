# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: --rest-api-id <api-id>, --stage-name prod

# Then start applying the recovery steps
aws apigateway update-stage --rest-api-id <api-id> --stage-name prod --patch-operations op=replace,path=/*/*/throttling/burstLimit,value=100
```
