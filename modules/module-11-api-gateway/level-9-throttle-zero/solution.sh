#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='ticketdash-api'].id | [0]" --output text)"
aws_local apigateway update-stage --rest-api-id "$API_ID" --stage-name v2 --patch-operations \
  'op=replace,path=/*/*/throttling/rateLimit,value=200' \
  'op=replace,path=/*/*/throttling/burstLimit,value=400' \
  'op=replace,path=/~1checkout/POST/throttling/rateLimit,value=15' \
  'op=replace,path=/~1checkout/POST/throttling/burstLimit,value=30' >/dev/null
