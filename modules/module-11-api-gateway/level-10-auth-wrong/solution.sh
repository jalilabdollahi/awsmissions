#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='vaultline-api'].id | [0]" --output text)"
AUTH_ID="$(aws_local apigateway get-authorizers --rest-api-id "$API_ID" --query 'items[?name==`partner-token`].id | [0]' --output text)"
aws_local apigateway update-authorizer --rest-api-id "$API_ID" --authorizer-id "$AUTH_ID" \
  --patch-operations 'op=replace,path=/identitySource,value=method.request.header.X-Vaultline-Token' >/dev/null
aws_local apigateway create-deployment --rest-api-id "$API_ID" --stage-name partner >/dev/null
