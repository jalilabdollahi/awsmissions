#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam create-role --role-name ledger-close-exec \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

pkg="$(mktemp -d)"
trap 'rm -rf "$pkg"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$pkg/close.zip" month_close.py)

# Created years ago, back when python3.6 was a thing.
aws_local lambda create-function --function-name ledger-month-close \
  --runtime python3.6 --handler month_close.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/ledger-close-exec" \
  --zip-file "fileb://$pkg/close.zip" >/dev/null

echo "ledger-month-close is deployed and finance is staring at an empty dashboard."
