# Solution

HTTP API Lambda authorizers can answer in two formats. By default (payload 2.0 without simple responses) API Gateway expects a full IAM policy document, and a bare `{"isAuthorized": true}` is not understood, which becomes a 500. Tell the authorizer to accept simple responses:

```bash
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='pinecone-metrics'].ApiId | [0]" --output text)
AUTH_ID=$(aws apigatewayv2 get-authorizers --api-id $API_ID --query 'Items[0].AuthorizerId' --output text)

aws apigatewayv2 get-authorizer --api-id $API_ID --authorizer-id $AUTH_ID
aws apigatewayv2 update-authorizer --api-id $API_ID --authorizer-id $AUTH_ID --enable-simple-responses
```
