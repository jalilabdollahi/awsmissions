#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

aws_local iam create-role --role-name coupon-redeemer-role --assume-role-policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
cp "$MISSION_DIR/workspace/redeem.py" "$tmp/redeem.py"
(cd "$tmp" && zip -q bundle.zip redeem.py)

aws_local lambda create-function --function-name coupon-redeemer --zip-file "fileb://$tmp/bundle.zip" \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/coupon-redeemer-role" --handler redeem.redeem --runtime python3.12 >/dev/null

# Before the incident the function worked: prove it once, then replay the "emergency pause".
aws_local lambda invoke --function-name coupon-redeemer --cli-binary-format raw-in-base64-out \
  --payload '{"code":"BRT-10-AAAAAA","cart_total":10}' "$tmp/warmup.json" >/dev/null
aws_local lambda put-function-concurrency --function-name coupon-redeemer \
  --reserved-concurrent-executions 0 >/dev/null

echo "coupon-redeemer has been 'paused' since the incident."
