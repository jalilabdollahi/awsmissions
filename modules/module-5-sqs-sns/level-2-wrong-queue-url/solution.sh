#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

prod_url="$(aws_local sqs get-queue-url --queue-name ticketdesk-support --query QueueUrl --output text)"
aws_local ssm put-parameter --name /ticketdesk/prod/support-queue-url \
  --type String --value "$prod_url" --overwrite
