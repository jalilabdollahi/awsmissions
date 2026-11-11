#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

zipdir="$(mktemp -d)"
trap 'rm -rf "$zipdir"' EXIT
python3 - "$zipdir/fn.zip" <<'PY'
import sys, zipfile
code = '''
def handler(event, context):
    zone = event["pathParameters"]["zone"]
    weight = float((event.get("queryStringParameters") or {}).get("weight", "0"))
    rates = {"eu": 1.9, "us": 2.6, "apac": 3.4}
    return {"zone": zone, "weight_kg": weight, "price_eur": round(rates.get(zone, 5.0) * weight, 2),
            "via": event["requestContext"]["http"]["method"], "path": event["rawPath"]}
'''
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.writestr("index.py", code)
PY

aws_local iam create-role --role-name fernwood-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name fernwood-pricing --runtime python3.12 --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/fernwood-role" --zip-file "fileb://$zipdir/fn.zip" >/dev/null

fw="$(aws_local apigatewayv2 create-api --name fernwood-quotes --protocol-type HTTP --query ApiId --output text)"
old_int="$(aws_local apigatewayv2 create-integration --api-id "$fw" --integration-type AWS_PROXY \
  --integration-uri "arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:fernwood-pricing" \
  --payload-format-version 1.0 --query IntegrationId --output text)"
aws_local apigatewayv2 create-route --api-id "$fw" --route-key 'GET /quotes/{zone}' --target "integrations/$old_int" >/dev/null
aws_local apigatewayv2 create-stage --api-id "$fw" --stage-name prod --auto-deploy >/dev/null

echo "fernwood-quotes is deployed and returns 500."
