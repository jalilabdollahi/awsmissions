# Solution

Methods are configured one by one: the GET on `/tickets` says nothing about POST. Add a POST method and point its own integration at the create function, then redeploy.

```bash
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='parcelpoint-help'].id | [0]" --output text)
RES_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`/tickets`].id | [0]' --output text)

aws apigateway put-method --rest-api-id $API_ID --resource-id $RES_ID --http-method POST --authorization-type NONE
aws apigateway put-integration --rest-api-id $API_ID --resource-id $RES_ID --http-method POST \
  --type AWS_PROXY --integration-http-method POST \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:parcelpoint-ticket-create/invocations

aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod
```

Do not use `ANY` pointing at the list function: that would answer POSTs with the list.
