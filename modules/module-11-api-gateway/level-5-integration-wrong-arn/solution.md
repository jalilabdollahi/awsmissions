# Solution

The integration URI names `invoice-renderr`, a function that does not exist. Patch just the URI of the existing integration:

```bash
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='invoicely-portal'].id | [0]" --output text)
RES_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`/invoices/latest`].id | [0]' --output text)

aws apigateway update-integration --rest-api-id $API_ID --resource-id $RES_ID --http-method GET \
  --patch-operations "op=replace,path=/uri,value=arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:invoice-renderer/invocations"

aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod
```

Do not point it at `invoice-renderer-staging`: it would also answer 200 but with sandbox data.
