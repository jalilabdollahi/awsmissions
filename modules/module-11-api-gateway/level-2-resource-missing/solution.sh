#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

qn_api="$(aws_local apigateway get-rest-apis --query "items[?name=='quillnote-api'].id | [0]" --output text)"
list_node="$(aws_local apigateway get-resources --rest-api-id "$qn_api" --query 'items[?path==`/notes`].id | [0]' --output text)"
item_node="$(aws_local apigateway create-resource --rest-api-id "$qn_api" --parent-id "$list_node" --path-part '{noteId}' --query id --output text)"
aws_local apigateway put-method --rest-api-id "$qn_api" --resource-id "$item_node" --http-method GET --authorization-type NONE >/dev/null
aws_local apigateway put-integration --rest-api-id "$qn_api" --resource-id "$item_node" --http-method GET \
  --type AWS_PROXY --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:quillnote-notes/invocations" >/dev/null
aws_local apigateway create-deployment --rest-api-id "$qn_api" --stage-name v1 >/dev/null
