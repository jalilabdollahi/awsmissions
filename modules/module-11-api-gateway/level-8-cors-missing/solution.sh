#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='zestlist-api'].id | [0]" --output text)"
RES_ID="$(aws_local apigateway get-resources --rest-api-id "$API_ID" --query 'items[?path==`/tasks`].id | [0]' --output text)"

# Preflight: OPTIONS answered by a MOCK integration.
aws_local apigateway put-method --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method OPTIONS --authorization-type NONE >/dev/null
aws_local apigateway put-integration --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method OPTIONS \
  --type MOCK --request-templates '{"application/json":"{\"statusCode\": 200}"}' >/dev/null
aws_local apigateway put-method-response --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method OPTIONS --status-code 200 \
  --response-parameters 'method.response.header.Access-Control-Allow-Origin=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Headers=false' >/dev/null
aws_local apigateway put-integration-response --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method OPTIONS --status-code 200 \
  --response-parameters file://cors-headers.json >/dev/null

# Actual response: GET must carry the origin header as well.
aws_local apigateway put-method-response --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method GET --status-code 200 \
  --response-parameters 'method.response.header.Access-Control-Allow-Origin=false' >/dev/null
aws_local apigateway put-integration-response --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method GET --status-code 200 \
  --response-parameters '{"method.response.header.Access-Control-Allow-Origin":"'"'https://app.zestlist.example'"'"}' >/dev/null

aws_local apigateway create-deployment --rest-api-id "$API_ID" --stage-name web >/dev/null
