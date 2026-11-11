#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
python3 - "$tmp" <<'PY'
import sys, zipfile
metrics = '''
def handler(event, context):
    return {"cpu_pct": 41, "queue_depth": 7, "caller": event["requestContext"].get("authorizer", {}).get("lambda", {}).get("team", "unknown")}
'''
bouncer = '''
def handler(event, context):
    key = (event.get("headers") or {}).get("x-pine-key")
    return {"isAuthorized": key == "pine-7a21", "context": {"team": "platform"}}
'''
for name, code in (("metrics", metrics), ("bouncer", bouncer)):
    with zipfile.ZipFile(f"{sys.argv[1]}/{name}.zip", "w") as z:
        z.writestr("index.py", code)
PY

aws_local iam create-role --role-name pinecone-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
for n in metrics bouncer; do
  aws_local lambda create-function --function-name "pinecone-$n" --runtime python3.12 --handler index.handler \
    --role "arn:aws:iam::${ACCOUNT_ID}:role/pinecone-role" --zip-file "fileb://$tmp/$n.zip" >/dev/null
done

API_ID="$(aws_local apigatewayv2 create-api --name pinecone-metrics --protocol-type HTTP --query ApiId --output text)"
INT_ID="$(aws_local apigatewayv2 create-integration --api-id "$API_ID" --integration-type AWS_PROXY \
  --integration-uri "arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:pinecone-metrics" \
  --payload-format-version 2.0 --query IntegrationId --output text)"
AUTH_ID="$(aws_local apigatewayv2 create-authorizer --api-id "$API_ID" --name pine-key --authorizer-type REQUEST \
  --authorizer-uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:pinecone-bouncer/invocations" \
  --identity-source '$request.header.x-pine-key' --authorizer-payload-format-version 2.0 --query AuthorizerId --output text)"
aws_local apigatewayv2 create-route --api-id "$API_ID" --route-key 'GET /metrics' --target "integrations/$INT_ID" \
  --authorization-type CUSTOM --authorizer-id "$AUTH_ID" >/dev/null
aws_local apigatewayv2 create-stage --api-id "$API_ID" --stage-name prod --auto-deploy >/dev/null

echo "pinecone-metrics has a Lambda authorizer. Every call fails with 500."
