#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb update-time-to-live --table-name loginly-sessions \
  --time-to-live-specification Enabled=false,AttributeName=expires >/dev/null
aws_local dynamodb update-time-to-live --table-name loginly-sessions \
  --time-to-live-specification Enabled=true,AttributeName=expiresAt >/dev/null
