#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigatewayv2 get-apis --query "Items[?Name=='mapleboard-http'].ApiId | [0]" --output text)"
aws_local apigatewayv2 update-api --api-id "$API_ID" \
  --cors-configuration 'AllowOrigins=https://boards.maple.example,AllowMethods=GET,POST,AllowHeaders=content-type,AllowCredentials=true,MaxAge=600' >/dev/null
