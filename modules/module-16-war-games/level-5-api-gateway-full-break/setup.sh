#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

aws_local iam create-role --role-name qm-catalog-role --assume-role-policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

cat > "$tmp/catalog.py" <<'PY'
import json

BOOKS = [
    {"isbn": "978-0-00-000001-1", "title": "Salt and Ledgers", "stock": 14},
    {"isbn": "978-0-00-000002-8", "title": "The Cartographer's Apprentice", "stock": 3},
]

def handler(event, context):
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"books": BOOKS}),
    }
PY
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],'catalog.py')" "$tmp/c.zip" "$tmp/catalog.py"
aws_local lambda create-function --function-name qm-catalog-api --runtime python3.12 --handler catalog.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/qm-catalog-role" --zip-file "fileb://$tmp/c.zip" >/dev/null
aws_local lambda wait function-active-v2 --function-name qm-catalog-api 2>/dev/null || sleep 2
aws_local lambda put-function-concurrency --function-name qm-catalog-api --reserved-concurrent-executions 0 >/dev/null

API="$(aws_local apigateway create-rest-api --name qm-catalog --query id --output text)"
ROOT="$(aws_local apigateway get-resources --rest-api-id "$API" --query 'items[0].id' --output text)"
RES="$(aws_local apigateway create-resource --rest-api-id "$API" --parent-id "$ROOT" --path-part books --query id --output text)"
aws_local apigateway put-method --rest-api-id "$API" --resource-id "$RES" --http-method GET \
  --authorization-type NONE --api-key-required >/dev/null
# Left over from the old naming: the integration still targets qm-catalog-api-v1.
aws_local apigateway put-integration --rest-api-id "$API" --resource-id "$RES" --http-method GET \
  --type AWS_PROXY --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:qm-catalog-api-v1/invocations" >/dev/null
aws_local apigateway create-deployment --rest-api-id "$API" --stage-name staging >/dev/null

KEY_ID="$(aws_local apigateway create-api-key --name qm-partner-key --enabled --query id --output text)"
PLAN="$(aws_local apigateway create-usage-plan --name qm-partners --api-stages "apiId=$API,stage=staging" \
  --throttle rateLimit=50,burstLimit=100 --query id --output text)"
aws_local apigateway create-usage-plan-key --usage-plan-id "$PLAN" --key-id "$KEY_ID" --key-type API_KEY >/dev/null

echo "INC-4417 is open: partners see 403, 404 and timeouts."
