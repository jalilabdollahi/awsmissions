#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Which rotator exists today?
arn="$(aws_local lambda list-functions \
  --query "Functions[?starts_with(FunctionName, 'pelican-rotate-orders-db')].FunctionArn | [0]" --output text)"

aws_local secretsmanager rotate-secret --secret-id pelican/orders-db/password \
  --rotation-lambda-arn "$arn" --rotation-rules AutomaticallyAfterDays=30 \
  --no-rotate-immediately >/dev/null
