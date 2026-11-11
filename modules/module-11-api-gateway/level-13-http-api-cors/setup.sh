#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stage_dir="$(mktemp -d)"
trap 'rm -rf "$stage_dir"' EXIT
python3 - "$stage_dir/fn.zip" <<'PY'
import sys, zipfile
code = '''
def handler(event, context):
    return {"boards": ["Sprint 41", "Launch checklist"], "method": event["requestContext"]["http"]["method"]}
'''
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.writestr("index.py", code)
PY

aws_local iam create-role --role-name mapleboard-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name mapleboard-boards --runtime python3.12 --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/mapleboard-role" --zip-file "fileb://$stage_dir/fn.zip" >/dev/null

hapi="$(aws_local apigatewayv2 create-api --name mapleboard-http --protocol-type HTTP --query ApiId --output text)"
proxy_int="$(aws_local apigatewayv2 create-integration --api-id "$hapi" --integration-type AWS_PROXY \
  --integration-uri "arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:mapleboard-boards" \
  --payload-format-version 2.0 --query IntegrationId --output text)"
aws_local apigatewayv2 create-route --api-id "$hapi" --route-key 'GET /boards' --target "integrations/$proxy_int" >/dev/null
aws_local apigatewayv2 create-route --api-id "$hapi" --route-key 'POST /boards' --target "integrations/$proxy_int" >/dev/null
aws_local apigatewayv2 create-stage --api-id "$hapi" --stage-name prod --auto-deploy >/dev/null

echo "mapleboard-http answers curl. Browsers refuse it."
