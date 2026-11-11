# Solution

A REST API is assembled from separate pieces, and each one has to exist: API, resource, method, integration, deployment to a stage.

```bash
API_ID=$(aws apigateway create-rest-api --name lantern-status-api --query id --output text)
ROOT_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)

RES_ID=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_ID \
  --path-part status --query id --output text)

aws apigateway put-method --rest-api-id $API_ID --resource-id $RES_ID \
  --http-method GET --authorization-type NONE

aws apigateway put-integration --rest-api-id $API_ID --resource-id $RES_ID --http-method GET \
  --type AWS_PROXY --integration-http-method POST \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:lantern-status/invocations

aws lambda add-permission --function-name lantern-status --statement-id apigw-status \
  --action lambda:InvokeFunction --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:000000000000:$API_ID/*/GET/status"

aws apigateway create-deployment --rest-api-id $API_ID --stage-name live
```

Call it: `curl "$AWS_ENDPOINT_URL/restapis/$API_ID/live/_user_request_/status"`.
