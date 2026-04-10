#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
tmpdir="$(mktemp -d)"
cat > "$tmpdir/index.py" <<'EOF'
import json

def lambda_handler(event, context):
    return {"statusCode": 200, "body": json.dumps("ok")}
EOF
(
  cd "$tmpdir"
  python3 - <<'EOF'
import zipfile
with zipfile.ZipFile('function.zip', 'w') as z:
    z.write('index.py')
EOF
)
aws_local iam create-role \
  --role-name s3-trigger-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1 || true
aws_local lambda create-function \
  --function-name upload-handler \
  --runtime python3.11 \
  --role arn:aws:iam::000000000000:role/s3-trigger-role \
  --handler index.lambda_handler \
  --zip-file fileb://"$tmpdir/function.zip" >/dev/null 2>&1 || true
aws_local lambda add-permission \
  --function-name upload-handler \
  --statement-id allow-s3 \
  --action lambda:InvokeFunction \
  --principal s3.amazonaws.com \
  --source-arn arn:aws:s3:::mission-bucket >/dev/null 2>&1 || true
rm -rf "$tmpdir"
aws_local s3api put-bucket-notification-configuration   --bucket mission-bucket   --notification-configuration '{"LambdaFunctionConfigurations":[{"Id":"upload-handler","LambdaFunctionArn":"arn:aws:lambda:us-east-1:000000000000:function:upload-handler","Events":["s3:ObjectRemoved:*"]}]}' >/dev/null
echo "Broken bucket created: mission-bucket (wrong notification event)"
