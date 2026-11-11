#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local sqs create-queue --queue-name ticketdesk-support >/dev/null
aws_local sqs create-queue --queue-name ticketdesk-support-staging >/dev/null

# The promotion copied the staging value into the production parameter.
staging_url="$(aws_local sqs get-queue-url --queue-name ticketdesk-support-staging --query QueueUrl --output text)"
aws_local ssm put-parameter --name /ticketdesk/prod/support-queue-url \
  --type String --value "$staging_url" >/dev/null
aws_local ssm put-parameter --name /ticketdesk/staging/support-queue-url \
  --type String --value "$staging_url" >/dev/null

echo "The prod API sends happily - to ticketdesk-support-staging."
