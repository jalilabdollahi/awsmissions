#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
python3 - "$tmp/fn.zip" <<'PY'
import sys, zipfile
code = '''
import json
def handler(event, context):
    sku = event.get("sku")
    qty = event.get("qty")
    if not sku:
        raise Exception("sku required")
    if not isinstance(qty, int):
        raise Exception("qty must be a number, got %r" % (qty,))
    return {"reserved": sku, "units": qty, "note": event.get("note", "")}
'''
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.writestr("index.py", code)
PY

aws_local iam create-role --role-name crateful-reserve-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name crateful-reserve --runtime python3.12 --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/crateful-reserve-role" --zip-file "fileb://$tmp/fn.zip" >/dev/null

API_ID="$(aws_local apigateway create-rest-api --name crateful-api --query id --output text)"
ROOT_ID="$(aws_local apigateway get-resources --rest-api-id "$API_ID" --query 'items[0].id' --output text)"
RES_ID="$(aws_local apigateway create-resource --rest-api-id "$API_ID" --parent-id "$ROOT_ID" --path-part reservations --query id --output text)"
aws_local apigateway put-method --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method POST --authorization-type NONE >/dev/null
aws_local apigateway put-integration --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method POST \
  --type AWS --integration-http-method POST --passthrough-behavior NEVER \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:crateful-reserve/invocations" \
  --request-templates "file://$MISSION_DIR/workspace/request-template.json" >/dev/null
aws_local apigateway put-method-response --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method POST --status-code 200 >/dev/null
aws_local apigateway put-method-response --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method POST --status-code 400 >/dev/null
aws_local apigateway put-integration-response --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method POST --status-code 200 >/dev/null
aws_local apigateway put-integration-response --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method POST --status-code 400 \
  --selection-pattern '.*(required|must be).*' >/dev/null
aws_local apigateway create-deployment --rest-api-id "$API_ID" --stage-name live >/dev/null

echo "POST /reservations reaches the function with empty values."
