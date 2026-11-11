# Solution

An API key alone opens nothing. A **usage plan** has to (a) include the API stage and (b) contain the key.

1. Complete `workspace/usage-plan.json` with the stage and the contract limits:

```json
{
  "name": "wanderpath-partner",
  "description": "Contract WP-2026-03",
  "apiStages": [{"apiId": "<api id>", "stage": "v1"}],
  "throttle": {"rateLimit": 20, "burstLimit": 40},
  "quota": {"limit": 10000, "period": "DAY"}
}
```

2. Create the plan and link only the partner key to it:

```bash
PLAN_ID=$(aws apigateway create-usage-plan --cli-input-json file://usage-plan.json --query id --output text)
KEY_ID=$(aws apigateway get-api-keys --query "items[?name=='trailmix-partner-key'].id | [0]" --output text)
aws apigateway create-usage-plan-key --usage-plan-id $PLAN_ID --key-id $KEY_ID --key-type API_KEY
```

3. Test: `curl -H "x-api-key: <value>" "$AWS_ENDPOINT_URL/restapis/$API_ID/v1/_user_request_/trails"` (the value comes from `get-api-keys --include-values`).
