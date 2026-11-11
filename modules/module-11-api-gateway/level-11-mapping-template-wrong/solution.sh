#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
tpl = ('{\n  "sku": "$input.path(\'$.productCode\')",\n  "qty": $input.path(\'$.quantity\'),\n'
       '  "note": "$util.escapeJavaScript($input.path(\'$.note\'))"\n}')
json.dump({"application/json": tpl}, open("request-template.json", "w"), indent=2)
PY

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='crateful-api'].id | [0]" --output text)"
RES_ID="$(aws_local apigateway get-resources --rest-api-id "$API_ID" --query 'items[?path==`/reservations`].id | [0]' --output text)"
aws_local apigateway put-integration --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method POST \
  --type AWS --integration-http-method POST --passthrough-behavior NEVER \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:crateful-reserve/invocations" \
  --request-templates file://request-template.json >/dev/null
aws_local apigateway create-deployment --rest-api-id "$API_ID" --stage-name live >/dev/null
