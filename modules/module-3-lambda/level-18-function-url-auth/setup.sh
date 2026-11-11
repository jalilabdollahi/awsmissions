#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam create-role --role-name invite-landing-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/landing.zip" landing.py)

for fn in invite-landing invite-admin; do
  aws_local lambda create-function --function-name "$fn" \
    --runtime python3.12 --handler landing.handle \
    --role "arn:aws:iam::${ACCOUNT_ID}:role/invite-landing-role" \
    --zip-file "fileb://$stage/landing.zip" >/dev/null
  # The template's secure default: IAM auth, and browsers limited to the sign-up page.
  aws_local lambda create-function-url-config --function-name "$fn" --auth-type AWS_IAM \
    --cors '{"AllowOrigins":["https://pebblestudio.example"],"AllowMethods":["POST"],"AllowHeaders":["content-type"]}' >/dev/null
done

echo "Both function URLs require AWS_IAM signatures; the public sign-up page cannot sign requests."
