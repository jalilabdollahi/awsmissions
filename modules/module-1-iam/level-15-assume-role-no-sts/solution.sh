#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

target="arn:aws:iam::${ACCOUNT_ID}:role/cobalt-audit-readonly"
tmp="$(mktemp)"
jq --arg arn "$target" \
  '.Statement += [{Sid: "SwitchToAuditRole", Effect: "Allow", Action: "sts:AssumeRole", Resource: $arn}]' \
  policy.json > "$tmp"
mv "$tmp" policy.json

aws_local iam put-user-policy --user-name cobalt-auditor --policy-name auditor-base \
  --policy-document file://policy.json
