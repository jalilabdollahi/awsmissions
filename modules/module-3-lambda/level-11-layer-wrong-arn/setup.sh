#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cat > "$tmpdir/index.py" <<'EOF'
import json

def lambda_handler(event, context):
    return {"statusCode": 200, "body": json.dumps("ok")}
EOF
mkdir -p "$tmpdir/python"
cat > "$tmpdir/python/util.py" <<'EOF'
VALUE = "layer-ok"
EOF
(
  cd "$tmpdir"
  python3 - <<'EOF'
import zipfile
with zipfile.ZipFile('function.zip', 'w') as z:
    z.write('index.py')
with zipfile.ZipFile('layer.zip', 'w') as z:
    z.write('python/util.py')
EOF
)
aws_local iam create-role   --role-name mission-lambda-role   --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1 || true
aws_local iam put-role-policy   --role-name mission-lambda-role   --policy-name mission-lambda-logs   --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],"Resource":"*"}]}' >/dev/null 2>&1 || true
aws_local lambda publish-layer-version   --layer-name mission-utils   --zip-file fileb://"$tmpdir/layer.zip"   --compatible-runtimes python3.11 >/dev/null 2>&1 || true
aws_local lambda create-function   --function-name mission-function   --runtime python3.11   --role arn:aws:iam::000000000000:role/mission-lambda-role   --handler index.lambda_handler   --layers arn:aws:lambda:us-east-1:000000000000:layer:missing-layer:1   --zip-file fileb://"$tmpdir/function.zip" >/dev/null 2>&1 || true

echo "Broken function created: layer ARN points to missing-layer:1 instead of mission-utils"
