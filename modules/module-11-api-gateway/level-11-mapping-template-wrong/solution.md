# Solution

The template reads fields that no longer exist (`$.product`, `$.qty`, `$.comment`), so every value is empty, and it quotes `qty`, which must be a JSON number. Rewrite it against the current partner contract, and escape the free-text note:

```
{
  "sku": "$input.path('$.productCode')",
  "qty": $input.path('$.quantity'),
  "note": "$util.escapeJavaScript($input.path('$.note'))"
}
```

`workspace/request-template.json` holds the current template as a JSON map from content type to template. Edit it, then update the integration and deploy:

```bash
aws apigateway put-integration --rest-api-id $API_ID --resource-id $RES_ID --http-method POST \
  --type AWS --integration-http-method POST --passthrough-behavior NEVER \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:crateful-reserve/invocations \
  --request-templates file://request-template.json
aws apigateway create-deployment --rest-api-id $API_ID --stage-name live
```
