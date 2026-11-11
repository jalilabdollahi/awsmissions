#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API="$(aws_local apigateway get-rest-apis --query "items[?name=='qm-catalog'].id | [0]" --output text)"
RES="$(aws_local apigateway get-resources --rest-api-id "$API" --query "items[?path=='/books'].id | [0]" --output text)"

# 1. Repoint the integration at the renamed function.
aws_local apigateway put-integration --rest-api-id "$API" --resource-id "$RES" --http-method GET \
  --type AWS_PROXY --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:qm-catalog-api/invocations" >/dev/null

# 2. Deploy to the stage partners actually call.
aws_local apigateway create-deployment --rest-api-id "$API" --stage-name prod >/dev/null

# 3. Add prod to the usage plan that holds the partner key.
PLAN="$(aws_local apigateway get-usage-plans --query "items[?name=='qm-partners'].id | [0]" --output text)"
aws_local apigateway update-usage-plan --usage-plan-id "$PLAN" \
  --patch-operations "op=add,path=/apiStages,value=${API}:prod" >/dev/null

# 4. Remove the zero concurrency cap.
aws_local lambda delete-function-concurrency --function-name qm-catalog-api
