#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

pkg="$(mktemp -d)"
trap 'rm -rf "$pkg"' EXIT
python3 - "$pkg/fn.zip" <<'PY'
import sys, zipfile
code = '''
import json
def handler(event, context):
    return {"statusCode": 200, "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"trails": ["Eagle Ridge Loop", "Mossy Hollow", "Three Lakes Traverse"]})}
'''
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.writestr("index.py", code)
PY

aws_local iam create-role --role-name trailmix-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name trailmix-trails --runtime python3.12 --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/trailmix-role" --zip-file "fileb://$pkg/fn.zip" >/dev/null

tm="$(aws_local apigateway create-rest-api --name trailmix-api --query id --output text)"
tmroot="$(aws_local apigateway get-resources --rest-api-id "$tm" --query 'items[0].id' --output text)"
trailsres="$(aws_local apigateway create-resource --rest-api-id "$tm" --parent-id "$tmroot" --path-part trails --query id --output text)"
aws_local apigateway put-method --rest-api-id "$tm" --resource-id "$trailsres" --http-method GET \
  --authorization-type NONE --api-key-required >/dev/null
aws_local apigateway put-integration --rest-api-id "$tm" --resource-id "$trailsres" --http-method GET \
  --type AWS_PROXY --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:trailmix-trails/invocations" >/dev/null
aws_local apigateway create-deployment --rest-api-id "$tm" --stage-name v1 >/dev/null

aws_local apigateway create-api-key --name trailmix-partner-key --enabled >/dev/null
aws_local apigateway create-api-key --name trailmix-trial-key --enabled >/dev/null

echo "Two keys exist, but no usage plan ties either of them to the API."
