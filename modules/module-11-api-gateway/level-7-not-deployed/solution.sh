#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='skyhook-weather'].id | [0]" --output text)"
aws_local apigateway create-deployment --rest-api-id "$API_ID" --stage-name prod \
  --description "release day" --variables tier=production >/dev/null
