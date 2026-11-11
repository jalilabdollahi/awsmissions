#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

pp="$(aws_local apigateway get-rest-apis --query "items[?name=='parcelpoint-help'].id | [0]" --output text)"
tickets_node="$(aws_local apigateway get-resources --rest-api-id "$pp" --query 'items[?path==`/tickets`].id | [0]' --output text)"
aws_local apigateway put-method --rest-api-id "$pp" --resource-id "$tickets_node" --http-method POST --authorization-type NONE >/dev/null
aws_local apigateway put-integration --rest-api-id "$pp" --resource-id "$tickets_node" --http-method POST \
  --type AWS_PROXY --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:parcelpoint-ticket-create/invocations" >/dev/null
aws_local apigateway create-deployment --rest-api-id "$pp" --stage-name prod >/dev/null
