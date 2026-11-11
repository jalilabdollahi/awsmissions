# Solution

Two separate things must be true: the preflight (`OPTIONS`) must be answered with the CORS headers, and the real `GET` response must carry `Access-Control-Allow-Origin` as well. With a non-proxy integration both are configured in method and integration responses.

1. Add OPTIONS with a MOCK integration (`workspace/cors-headers.json` has the three header values, already wrapped in the single quotes API Gateway requires for static values):

```bash
aws apigateway put-method --rest-api-id $API_ID --resource-id $RES_ID --http-method OPTIONS --authorization-type NONE
aws apigateway put-integration --rest-api-id $API_ID --resource-id $RES_ID --http-method OPTIONS \
  --type MOCK --request-templates '{"application/json":"{\"statusCode\": 200}"}'
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $RES_ID --http-method OPTIONS --status-code 200 \
  --response-parameters 'method.response.header.Access-Control-Allow-Origin=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Headers=false'
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $RES_ID --http-method OPTIONS --status-code 200 \
  --response-parameters file://cors-headers.json
```

2. Add the origin header to the GET response:

```bash
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $RES_ID --http-method GET --status-code 200 \
  --response-parameters 'method.response.header.Access-Control-Allow-Origin=false'
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $RES_ID --http-method GET --status-code 200 \
  --response-parameters '{"method.response.header.Access-Control-Allow-Origin":"'"'https://app.zestlist.example'"'"}'
```

3. Redeploy: `aws apigateway create-deployment --rest-api-id $API_ID --stage-name web`.
