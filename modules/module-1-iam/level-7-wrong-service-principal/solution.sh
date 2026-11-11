#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Swap the copied EC2 service principal for the on-call engineer's user ARN.
tmp="$(mktemp)"
jq --arg who "arn:aws:iam::${ACCOUNT_ID}:user/sre-oncall" \
  '.Statement[0].Principal = {AWS: $who}' trust-policy.json > "$tmp"
mv "$tmp" trust-policy.json

aws_local iam update-assume-role-policy --role-name sre-breakglass \
  --policy-document file://trust-policy.json
