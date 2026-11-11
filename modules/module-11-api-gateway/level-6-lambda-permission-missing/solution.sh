#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='cobaltpay-rates'].id | [0]" --output text)"
aws_local lambda remove-permission --function-name cobaltpay-fx-rates --statement-id allow-old-api
aws_local lambda add-permission --function-name cobaltpay-fx-rates --statement-id allow-rates-api \
  --action lambda:InvokeFunction --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:${ACCOUNT_ID}:${API_ID}/*/GET/rates" >/dev/null
