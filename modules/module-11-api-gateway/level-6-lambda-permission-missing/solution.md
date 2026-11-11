# Solution

Read the function's policy, delete the grant for the destroyed API and add one for the current API id, scoped to the one method and path it needs:

```bash
aws lambda get-policy --function-name cobaltpay-fx-rates

API_ID=$(aws apigateway get-rest-apis --query "items[?name=='cobaltpay-rates'].id | [0]" --output text)

aws lambda remove-permission --function-name cobaltpay-fx-rates --statement-id allow-old-api

aws lambda add-permission --function-name cobaltpay-fx-rates \
  --statement-id allow-rates-api \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:000000000000:$API_ID/*/GET/rates"
```

The SourceArn format is `arn:aws:execute-api:REGION:ACCOUNT:API_ID/STAGE/METHOD/PATH`; `*` for the stage lets every stage of this API call the function.
