# Solution

```bash
# Edit the local mission artifact first
$EDITOR usage-plan.json
# This edited file applies to: --name mission-plan

# Then apply the fix
aws apigateway create-usage-plan --name mission-plan --api-stages apiId=<api-id>,stage=prod
```
