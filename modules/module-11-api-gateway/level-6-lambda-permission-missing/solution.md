# Solution

```bash
# Edit the local mission artifact first
$EDITOR policy.json
# This edited file applies to: --function-name mission-function

# Then apply the fix
aws lambda add-permission --function-name mission-function --statement-id allow-apigw --action lambda:InvokeFunction --principal apigateway.amazonaws.com
```
