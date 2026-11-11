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
    return {"statusCode": 200, "body": json.dumps({"route": event.get("resource"), "ok": True})}
'''
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.writestr("index.py", code)
PY

aws_local iam create-role --role-name ticketdash-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name ticketdash-handler --runtime python3.12 --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/ticketdash-role" --zip-file "fileb://$tmp/fn.zip" >/dev/null
URI="arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:ticketdash-handler/invocations"

API_ID="$(aws_local apigateway create-rest-api --name ticketdash-api --query id --output text)"
ROOT_ID="$(aws_local apigateway get-resources --rest-api-id "$API_ID" --query 'items[0].id' --output text)"
for spec in "events:GET" "checkout:POST"; do
  part="${spec%%:*}"; verb="${spec##*:}"
  RES_ID="$(aws_local apigateway create-resource --rest-api-id "$API_ID" --parent-id "$ROOT_ID" --path-part "$part" --query id --output text)"
  aws_local apigateway put-method --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method "$verb" --authorization-type NONE >/dev/null
  aws_local apigateway put-integration --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method "$verb" \
    --type AWS_PROXY --integration-http-method POST --uri "$URI" >/dev/null
done
aws_local apigateway create-deployment --rest-api-id "$API_ID" --stage-name v2 >/dev/null
aws_local apigateway update-stage --rest-api-id "$API_ID" --stage-name v2 --patch-operations \
  'op=replace,path=/*/*/throttling/rateLimit,value=0' 'op=replace,path=/*/*/throttling/burstLimit,value=0' >/dev/null

echo "Stage v2 of ticketdash-api is throttled to zero."
