# Solution

An API only becomes reachable through a stage. `dev` exists, `prod` doesn't. Create a deployment into a new stage named `prod` and set the stage variable at the same time:

```bash
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='skyhook-weather'].id | [0]" --output text)

aws apigateway get-stages --rest-api-id $API_ID

aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod \
  --description "release day" --variables tier=production
```

Check with `curl "$AWS_ENDPOINT_URL/restapis/$API_ID/prod/_user_request_/conditions"`.
