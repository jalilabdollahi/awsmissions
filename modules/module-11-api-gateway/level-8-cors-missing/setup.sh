#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT
python3 - "$build/fn.zip" <<'PY'
import sys, zipfile
code = '''
def handler(event, context):
    return {"tasks": [{"id": 1, "title": "Water the ferns"}, {"id": 2, "title": "Renew passport"}]}
'''
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.writestr("index.py", code)
PY

aws_local iam create-role --role-name zestlist-tasks-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name zestlist-tasks --runtime python3.12 --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/zestlist-tasks-role" --zip-file "fileb://$build/fn.zip" >/dev/null

zl="$(aws_local apigateway create-rest-api --name zestlist-api --query id --output text)"
rootres="$(aws_local apigateway get-resources --rest-api-id "$zl" --query 'items[0].id' --output text)"
tasksres="$(aws_local apigateway create-resource --rest-api-id "$zl" --parent-id "$rootres" --path-part tasks --query id --output text)"
aws_local apigateway put-method --rest-api-id "$zl" --resource-id "$tasksres" --http-method GET --authorization-type NONE >/dev/null
aws_local apigateway put-integration --rest-api-id "$zl" --resource-id "$tasksres" --http-method GET \
  --type AWS --integration-http-method POST --passthrough-behavior WHEN_NO_MATCH \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:zestlist-tasks/invocations" >/dev/null
aws_local apigateway put-method-response --rest-api-id "$zl" --resource-id "$tasksres" --http-method GET --status-code 200 >/dev/null
aws_local apigateway put-integration-response --rest-api-id "$zl" --resource-id "$tasksres" --http-method GET --status-code 200 >/dev/null
aws_local apigateway create-deployment --rest-api-id "$zl" --stage-name web >/dev/null

echo "zestlist-api answers curl. Browsers block it."
