# Solution

Lambda proxy integrations on HTTP APIs have a **payload format version**. The function was written for 2.0 (`requestContext.http.method`, `rawPath`, `pathParameters`) but the integration sends version 1.0 events (`httpMethod`, `path`...), so the function raises a `KeyError` and API Gateway answers 500. Switch the integration to 2.0:

```bash
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='fernwood-quotes'].ApiId | [0]" --output text)
INT_ID=$(aws apigatewayv2 get-integrations --api-id $API_ID --query 'Items[0].IntegrationId' --output text)

aws apigatewayv2 get-integration --api-id $API_ID --integration-id $INT_ID --query PayloadFormatVersion
aws apigatewayv2 update-integration --api-id $API_ID --integration-id $INT_ID --payload-format-version 2.0
```
