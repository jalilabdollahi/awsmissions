#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam attach-group-policy --group-name helpdesk-agents \
  --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/attachments-agent"
