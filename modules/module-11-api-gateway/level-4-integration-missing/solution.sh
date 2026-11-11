#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

fn_arn="$(aws_local lambda get-function --function-name brewbook-search --query Configuration.FunctionArn --output text)"
bb="$(aws_local apigateway get-rest-apis --query "items[?name=='brewbook-api'].id | [0]" --output text)"
brews_node="$(aws_local apigateway get-resources --rest-api-id "$bb" --query 'items[?path==`/brews`].id | [0]' --output text)"

# The method already exists; only the integration behind it is missing.
aws_local apigateway put-integration --http-method GET --type AWS_PROXY \
  --rest-api-id "$bb" --resource-id "$brews_node" --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${fn_arn}/invocations" >/dev/null

aws_local apigateway create-deployment --stage-name test --rest-api-id "$bb" >/dev/null
