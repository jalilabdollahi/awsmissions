#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
python3 - "$tmp" <<'PY'
import sys, zipfile
docs = '''
import json
def handler(event, context):
    return {"statusCode": 200, "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"documents": ["statement-2026-10.pdf", "kyc-bundle-204.zip"]})}
'''
auth = '''
def handler(event, context):
    token = event.get("authorizationToken")
    effect = "Allow" if token == "vl-partner-7731" else "Deny"
    return {"principalId": "partner-bank",
            "policyDocument": {"Version": "2012-10-17", "Statement": [
                {"Action": "execute-api:Invoke", "Effect": effect, "Resource": event.get("methodArn", "*")}]}}
'''
for name, code in (("docs", docs), ("auth", auth)):
    with zipfile.ZipFile(f"{sys.argv[1]}/{name}.zip", "w") as z:
        z.writestr("index.py", code)
PY

aws_local iam create-role --role-name vaultline-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name vaultline-documents --runtime python3.12 --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/vaultline-role" --zip-file "fileb://$tmp/docs.zip" >/dev/null
aws_local lambda create-function --function-name vaultline-gatekeeper --runtime python3.12 --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/vaultline-role" --zip-file "fileb://$tmp/auth.zip" >/dev/null

API_ID="$(aws_local apigateway create-rest-api --name vaultline-api --query id --output text)"
ROOT_ID="$(aws_local apigateway get-resources --rest-api-id "$API_ID" --query 'items[0].id' --output text)"
RES_ID="$(aws_local apigateway create-resource --rest-api-id "$API_ID" --parent-id "$ROOT_ID" --path-part documents --query id --output text)"
AUTH_ID="$(aws_local apigateway create-authorizer --rest-api-id "$API_ID" --name partner-token --type TOKEN \
  --authorizer-uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:vaultline-gatekeeper/invocations" \
  --identity-source method.request.header.Authorization --query id --output text)"
aws_local apigateway put-method --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method GET \
  --authorization-type CUSTOM --authorizer-id "$AUTH_ID" >/dev/null
aws_local apigateway put-integration --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method GET \
  --type AWS_PROXY --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:vaultline-documents/invocations" >/dev/null
aws_local apigateway create-deployment --rest-api-id "$API_ID" --stage-name partner >/dev/null

echo "vaultline-api is protected by a token authorizer. Partners are all getting 401."
