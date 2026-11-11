# Solution

The method exists but has no integration, so API Gateway has nothing to call. Add a Lambda proxy integration to the existing GET method and redeploy:

```bash
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='brewbook-api'].id | [0]" --output text)
RES_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`/brews`].id | [0]' --output text)

aws apigateway put-integration --rest-api-id $API_ID --resource-id $RES_ID --http-method GET \
  --type AWS_PROXY --integration-http-method POST \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:brewbook-search/invocations

aws apigateway create-deployment --rest-api-id $API_ID --stage-name test
```

`--type AWS_PROXY` is what makes the query string reach the function inside the event. A plain `AWS` (non-proxy) integration would need explicit mapping templates.
