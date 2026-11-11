#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
python3 - "$scratch/fn.zip" <<'PY'
import sys, zipfile
code = '''
import json
def handler(event, context):
    tier = (event.get("stageVariables") or {}).get("tier", "unknown")
    return {"statusCode": 200, "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"wind_kt": 11, "visibility_km": 9, "answered_by": tier})}
'''
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.writestr("index.py", code)
PY

aws_local iam create-role --role-name skyhook-conditions-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name skyhook-conditions --runtime python3.12 --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/skyhook-conditions-role" --zip-file "fileb://$scratch/fn.zip" >/dev/null

sky="$(aws_local apigateway create-rest-api --name skyhook-weather --query id --output text)"
slash="$(aws_local apigateway get-resources --rest-api-id "$sky" --query 'items[0].id' --output text)"
cond="$(aws_local apigateway create-resource --rest-api-id "$sky" --parent-id "$slash" --path-part conditions --query id --output text)"
aws_local apigateway put-method --rest-api-id "$sky" --resource-id "$cond" --http-method GET --authorization-type NONE >/dev/null
aws_local apigateway put-integration --rest-api-id "$sky" --resource-id "$cond" --http-method GET \
  --type AWS_PROXY --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:skyhook-conditions/invocations" >/dev/null
aws_local apigateway create-deployment --rest-api-id "$sky" --stage-name dev --variables tier=development >/dev/null

echo "skyhook-weather answers on dev. The stage prod does not exist."
