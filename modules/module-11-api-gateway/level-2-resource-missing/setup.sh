#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
python3 - "$tmp/fn.zip" <<'PY'
import sys, zipfile
code = '''
import json
NOTES = {"n-204": "Buy oat milk", "n-205": "Call the dentist"}
def handler(event, context):
    params = event.get("pathParameters") or {}
    if event.get("resource") == "/notes":
        return {"statusCode": 200, "body": json.dumps({"notes": sorted(NOTES)})}
    note_id = params.get("noteId")
    if not note_id:
        return {"statusCode": 400, "body": json.dumps({"error": "noteId missing"})}
    if note_id not in NOTES:
        return {"statusCode": 404, "body": json.dumps({"error": "no such note"})}
    return {"statusCode": 200, "body": json.dumps({"noteId": note_id, "text": NOTES[note_id]})}
'''
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.writestr("index.py", code)
PY

aws_local iam create-role --role-name quillnote-lambda \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name quillnote-notes --runtime python3.12 \
  --handler index.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/quillnote-lambda" \
  --zip-file "fileb://$tmp/fn.zip" >/dev/null

URI="arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:quillnote-notes/invocations"
API_ID="$(aws_local apigateway create-rest-api --name quillnote-api --query id --output text)"
ROOT_ID="$(aws_local apigateway get-resources --rest-api-id "$API_ID" --query 'items[0].id' --output text)"
NOTES_ID="$(aws_local apigateway create-resource --rest-api-id "$API_ID" --parent-id "$ROOT_ID" --path-part notes --query id --output text)"
aws_local apigateway put-method --rest-api-id "$API_ID" --resource-id "$NOTES_ID" --http-method GET --authorization-type NONE >/dev/null
aws_local apigateway put-integration --rest-api-id "$API_ID" --resource-id "$NOTES_ID" --http-method GET \
  --type AWS_PROXY --integration-http-method POST --uri "$URI" >/dev/null
aws_local lambda add-permission --function-name quillnote-notes --statement-id apigw --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:${ACCOUNT_ID}:${API_ID}/*/*/notes*" >/dev/null
aws_local apigateway create-deployment --rest-api-id "$API_ID" --stage-name v1 >/dev/null

echo "quillnote-api serves GET /notes. Opening a single note fails."
