# Solution

A TOKEN authorizer reads the credential from exactly one place, its **identity source** (`method.request.header.Authorization` by default). Partners send `X-Vaultline-Token`, so API Gateway never finds a token and answers 401 before even calling the function. Point the identity source at the real header:

```bash
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='vaultline-api'].id | [0]" --output text)
AUTH_ID=$(aws apigateway get-authorizers --rest-api-id $API_ID --query 'items[0].id' --output text)

aws apigateway get-authorizer --rest-api-id $API_ID --authorizer-id $AUTH_ID

aws apigateway update-authorizer --rest-api-id $API_ID --authorizer-id $AUTH_ID \
  --patch-operations 'op=replace,path=/identitySource,value=method.request.header.X-Vaultline-Token'

aws apigateway create-deployment --rest-api-id $API_ID --stage-name partner
```
