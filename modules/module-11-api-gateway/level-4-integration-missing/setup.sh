#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
python3 - "$tmp/fn.zip" <<'PY'
import sys, zipfile
code = '''
import json
BREWS = [
    {"id": "b-2", "name": "Morning Glory", "roast": "light"},
    {"id": "b-11", "name": "Midnight Oil", "roast": "dark"},
    {"id": "b-14", "name": "Charcoal Cat", "roast": "dark"},
]
def handler(event, context):
    roast = (event.get("queryStringParameters") or {}).get("roast")
    found = [b["id"] for b in BREWS if roast is None or b["roast"] == roast]
    return {"statusCode": 200, "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"roast": roast, "ids": found})}
'''
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.writestr("index.py", code)
PY

aws_local iam create-role --role-name brewbook-search-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name brewbook-search --runtime python3.12 \
  --handler index.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/brewbook-search-role" \
  --zip-file "fileb://$tmp/fn.zip" >/dev/null

API_ID="$(aws_local apigateway create-rest-api --name brewbook-api --query id --output text)"
ROOT_ID="$(aws_local apigateway get-resources --rest-api-id "$API_ID" --query 'items[0].id' --output text)"
RES_ID="$(aws_local apigateway create-resource --rest-api-id "$API_ID" --parent-id "$ROOT_ID" --path-part brews --query id --output text)"
aws_local apigateway put-method --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method GET --authorization-type NONE >/dev/null
aws_local apigateway create-deployment --rest-api-id "$API_ID" --stage-name test >/dev/null

echo "GET /brews is declared on brewbook-api but leads nowhere."
