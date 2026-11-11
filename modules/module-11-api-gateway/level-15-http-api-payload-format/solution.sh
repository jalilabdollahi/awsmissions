#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigatewayv2 get-apis --query "Items[?Name=='fernwood-quotes'].ApiId | [0]" --output text)"
INT_ID="$(aws_local apigatewayv2 get-integrations --api-id "$API_ID" --query 'Items[0].IntegrationId' --output text)"
aws_local apigatewayv2 update-integration --api-id "$API_ID" --integration-id "$INT_ID" --payload-format-version 2.0 >/dev/null
