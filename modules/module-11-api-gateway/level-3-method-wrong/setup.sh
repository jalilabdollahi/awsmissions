#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
python3 - "$tmp" <<'PY'
import sys, zipfile
lister = '''
import json
def handler(event, context):
    return {"statusCode": 200, "body": json.dumps({"tickets": [{"id": "t-1", "title": "Parcel lost"}], "via": "list"})}
'''
creator = '''
import json
def handler(event, context):
    try:
        data = json.loads(event.get("body") or "{}")
    except ValueError:
        return {"statusCode": 400, "body": json.dumps({"error": "body must be JSON"})}
    if not data.get("title"):
        return {"statusCode": 400, "body": json.dumps({"error": "title is required"})}
    return {"statusCode": 201, "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"id": "t-new", "title": data["title"], "via": "create"})}
'''
for name, code in (("list", lister), ("create", creator)):
    with zipfile.ZipFile(f"{sys.argv[1]}/{name}.zip", "w") as z:
        z.writestr("index.py", code)
PY

aws_local iam create-role --role-name parcelpoint-help-lambda \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
for kind in list create; do
  aws_local lambda create-function --function-name "parcelpoint-ticket-$kind" --runtime python3.12 \
    --handler index.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/parcelpoint-help-lambda" \
    --zip-file "fileb://$tmp/$kind.zip" >/dev/null
done

API_ID="$(aws_local apigateway create-rest-api --name parcelpoint-help --query id --output text)"
ROOT_ID="$(aws_local apigateway get-resources --rest-api-id "$API_ID" --query 'items[0].id' --output text)"
RES_ID="$(aws_local apigateway create-resource --rest-api-id "$API_ID" --parent-id "$ROOT_ID" --path-part tickets --query id --output text)"
aws_local apigateway put-method --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method GET --authorization-type NONE >/dev/null
aws_local apigateway put-integration --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method GET \
  --type AWS_PROXY --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:parcelpoint-ticket-list/invocations" >/dev/null
aws_local apigateway create-deployment --rest-api-id "$API_ID" --stage-name prod >/dev/null

echo "parcelpoint-help lists tickets but cannot create them."
