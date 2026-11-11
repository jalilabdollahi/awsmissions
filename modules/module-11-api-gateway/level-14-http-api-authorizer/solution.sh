#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigatewayv2 get-apis --query "Items[?Name=='pinecone-metrics'].ApiId | [0]" --output text)"
AUTH_ID="$(aws_local apigatewayv2 get-authorizers --api-id "$API_ID" --query "Items[?Name=='pine-key'].AuthorizerId | [0]" --output text)"
aws_local apigatewayv2 update-authorizer --api-id "$API_ID" --authorizer-id "$AUTH_ID" --enable-simple-responses >/dev/null
