# Solution

An HTTP API has a single `CorsConfiguration`. API Gateway then answers preflights itself and adds the headers to real responses. List the exact origin, the methods and headers, and allow credentials:

```bash
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='mapleboard-http'].ApiId | [0]" --output text)

aws apigatewayv2 update-api --api-id $API_ID \
  --cors-configuration 'AllowOrigins=https://boards.maple.example,AllowMethods=GET,POST,AllowHeaders=content-type,AllowCredentials=true,MaxAge=600'
```

Check the result with:

```bash
curl -i -X OPTIONS -H 'Origin: https://boards.maple.example' -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type' \
  "$AWS_ENDPOINT_URL/restapis/$API_ID/prod/_user_request_/boards"
```
