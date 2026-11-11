#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local lambda update-function-url-config --function-name invite-landing \
  --auth-type NONE >/dev/null
aws_local lambda add-permission --function-name invite-landing \
  --statement-id public-url-access --action lambda:InvokeFunctionUrl \
  --principal '*' --function-url-auth-type NONE >/dev/null
