#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local secretsmanager create-secret --name nimbus/exporter/api-token \
  --secret-string '{"token":"nm_live_5aa90c"}' >/dev/null
aws_local secretsmanager create-secret --name nimbus/billing/master \
  --secret-string '{"card_vault":"never-for-the-exporter"}' >/dev/null

aws_local iam create-role --role-name nimbus-bare \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

aws_local iam create-user --user-name nimbus-ci >/dev/null
creds="$(aws_local iam create-access-key --user-name nimbus-ci \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text)"
akid="$(printf '%s' "$creds" | awk '{print $1}')"
secret="$(printf '%s' "$creds" | awk '{print $2}')"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cat > "$work/exporter.py" <<'PY'
import os

def handler(event, context):
    return {"env": os.environ.get("APP_ENV"), "secret": os.environ.get("TOKEN_SECRET_ID")}
PY
python3 - "$work" <<'PY'
import sys, zipfile
w = sys.argv[1]
with zipfile.ZipFile(w + "/exporter.zip", "w") as z:
    z.write(w + "/exporter.py", "exporter.py")
PY

aws_local lambda create-function --function-name nimbus-exporter --runtime python3.12 \
  --handler exporter.handler --zip-file "fileb://$work/exporter.zip" \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/nimbus-bare" \
  --environment "Variables={AWS_ACCESS_KEY_ID=$akid,AWS_SECRET_ACCESS_KEY=$secret,APP_ENV=prod,TOKEN_SECRET_ID=nimbus/exporter/api-token}" >/dev/null

echo "nimbus-exporter runs with CI keys in its environment and an empty execution role."
