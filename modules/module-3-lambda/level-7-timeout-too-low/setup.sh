#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

trust="$(jq -cn '{Version:"2012-10-17",Statement:[{Effect:"Allow",Principal:{Service:"lambda.amazonaws.com"},Action:"sts:AssumeRole"}]}')"
role_arn="$(aws_local iam create-role --role-name statement-renderer-role \
  --assume-role-policy-document "$trust" --query Role.Arn --output text)"

archive="$(mktemp -u).zip"
trap 'rm -f "$archive"' EXIT
python3 -c 'import sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.write(sys.argv[2], "renderer.py")' "$archive" "$MISSION_DIR/workspace/renderer.py"

# 3 seconds is the project template's default timeout.
aws_local lambda create-function --function-name statement-renderer \
  --runtime python3.12 --handler renderer.render --role "$role_arn" \
  --timeout 3 --zip-file "fileb://$archive" >/dev/null

echo "statement-renderer is deployed with the template's 3 second timeout."
