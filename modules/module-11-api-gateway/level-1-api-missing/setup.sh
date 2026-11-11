#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
python3 - "$tmp/fn.zip" <<'PY'
import sys, zipfile
code = '''
import json
def handler(event, context):
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"service": "lantern", "state": "operational", "build": "2026.11-a7f3"}),
    }
'''
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.writestr("index.py", code)
PY

aws_local iam create-role --role-name lantern-status-exec \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name lantern-status --runtime python3.12 \
  --handler index.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/lantern-status-exec" \
  --zip-file "fileb://$tmp/fn.zip" >/dev/null

echo "lantern-status (Lambda) is deployed. There is no API in front of it."
