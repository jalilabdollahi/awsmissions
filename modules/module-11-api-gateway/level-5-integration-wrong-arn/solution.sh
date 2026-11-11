#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

inv="$(aws_local apigateway get-rest-apis --query "items[?name=='invoicely-portal'].id | [0]" --output text)"
latest_node="$(aws_local apigateway get-resources --rest-api-id "$inv" --query 'items[?path==`/invoices/latest`].id | [0]' --output text)"
aws_local apigateway update-integration --rest-api-id "$inv" --resource-id "$latest_node" --http-method GET \
  --patch-operations "op=replace,path=/uri,value=arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:invoice-renderer/invocations" >/dev/null
aws_local apigateway create-deployment --rest-api-id "$inv" --stage-name prod >/dev/null
