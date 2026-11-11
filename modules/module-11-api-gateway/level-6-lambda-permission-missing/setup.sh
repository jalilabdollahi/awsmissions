#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
python3 - "$work/fn.zip" <<'PY'
import sys, zipfile
code = '''
import json
def handler(event, context):
    return {"statusCode": 200, "body": json.dumps({"base": "EUR", "USD": 1.08, "GBP": 0.86})}
'''
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.writestr("index.py", code)
PY

aws_local iam create-role --role-name cobaltpay-fx-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name cobaltpay-fx-rates --runtime python3.12 --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/cobaltpay-fx-role" --zip-file "fileb://$work/fn.zip" >/dev/null

# The grant for the API that was destroyed during the rebuild.
aws_local lambda add-permission --function-name cobaltpay-fx-rates --statement-id allow-old-api \
  --action lambda:InvokeFunction --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:${ACCOUNT_ID}:x7k2m9q4ab/*/GET/rates" >/dev/null

rates_api="$(aws_local apigateway create-rest-api --name cobaltpay-rates --query id --output text)"
top="$(aws_local apigateway get-resources --rest-api-id "$rates_api" --query 'items[0].id' --output text)"
rates_res="$(aws_local apigateway create-resource --rest-api-id "$rates_api" --parent-id "$top" --path-part rates --query id --output text)"
aws_local apigateway put-method --rest-api-id "$rates_api" --resource-id "$rates_res" --http-method GET --authorization-type NONE >/dev/null
aws_local apigateway put-integration --rest-api-id "$rates_api" --resource-id "$rates_res" --http-method GET \
  --type AWS_PROXY --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:cobaltpay-fx-rates/invocations" >/dev/null
aws_local apigateway create-deployment --rest-api-id "$rates_api" --stage-name live >/dev/null

echo "cobaltpay-rates is live. The function's policy still trusts the old API."
