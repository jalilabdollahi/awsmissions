#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# `update-` merges into the existing config; `put-` would reset retries to the default of 2.
aws_local lambda update-function-event-invoke-config --function-name sms-notifier \
  --destination-config "{\"OnFailure\":{\"Destination\":\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:sms-failed-deliveries\"}}" >/dev/null
