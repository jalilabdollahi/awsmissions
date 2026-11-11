#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local lambda add-permission --function-name rate-quote-engine \
  --statement-id allow-shipright-invoke --action lambda:InvokeFunction \
  --principal "arn:aws:iam::${ACCOUNT_ID}:user/partner-shipright" >/dev/null
