# Solution

Add a child resource under `/notes` whose path part is `{noteId}`, give it a GET method and the same Lambda proxy integration, then redeploy to stage `v1`.

```bash
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='quillnote-api'].id | [0]" --output text)
NOTES_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`/notes`].id | [0]' --output text)

ONE_ID=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $NOTES_ID \
  --path-part '{noteId}' --query id --output text)

aws apigateway put-method --rest-api-id $API_ID --resource-id $ONE_ID --http-method GET --authorization-type NONE
aws apigateway put-integration --rest-api-id $API_ID --resource-id $ONE_ID --http-method GET \
  --type AWS_PROXY --integration-http-method POST \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:quillnote-notes/invocations

aws apigateway create-deployment --rest-api-id $API_ID --stage-name v1
```

The braces in the path part make the segment a path parameter, and its name (`noteId`) is the key the Lambda sees in `event.pathParameters`.
