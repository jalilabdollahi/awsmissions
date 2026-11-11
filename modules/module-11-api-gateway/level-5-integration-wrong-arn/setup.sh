#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
python3 - "$tmp" <<'PY'
import sys, zipfile
tpl = '''
import json
def handler(event, context):
    return {"statusCode": 200, "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"invoice": "INV-2026-1187", "total": "249.00 EUR", "environment": "%s"})}
'''
for name, env in (("prod", "production"), ("staging", "staging")):
    with zipfile.ZipFile(f"{sys.argv[1]}/{name}.zip", "w") as z:
        z.writestr("index.py", tpl % env)
PY

aws_local iam create-role --role-name invoicely-render-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name invoice-renderer --runtime python3.12 --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/invoicely-render-role" --zip-file "fileb://$tmp/prod.zip" >/dev/null
aws_local lambda create-function --function-name invoice-renderer-staging --runtime python3.12 --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/invoicely-render-role" --zip-file "fileb://$tmp/staging.zip" >/dev/null

API_ID="$(aws_local apigateway create-rest-api --name invoicely-portal --query id --output text)"
ROOT_ID="$(aws_local apigateway get-resources --rest-api-id "$API_ID" --query 'items[0].id' --output text)"
INV_ID="$(aws_local apigateway create-resource --rest-api-id "$API_ID" --parent-id "$ROOT_ID" --path-part invoices --query id --output text)"
LATEST_ID="$(aws_local apigateway create-resource --rest-api-id "$API_ID" --parent-id "$INV_ID" --path-part latest --query id --output text)"
aws_local apigateway put-method --rest-api-id "$API_ID" --resource-id "$LATEST_ID" --http-method GET --authorization-type NONE >/dev/null
# The hand-typed ARN has a typo: "renderr".
aws_local apigateway put-integration --rest-api-id "$API_ID" --resource-id "$LATEST_ID" --http-method GET \
  --type AWS_PROXY --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:invoice-renderr/invocations" >/dev/null
aws_local apigateway create-deployment --rest-api-id "$API_ID" --stage-name prod >/dev/null

echo "invoicely-portal is deployed. GET /invoices/latest fails."
