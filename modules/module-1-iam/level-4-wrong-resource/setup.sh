#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

prod_url="$(aws_local sqs create-queue --queue-name orders-prod --query QueueUrl --output text)"
aws_local sqs create-queue --queue-name orders-dlq >/dev/null
aws_local sqs send-message --queue-url "$prod_url" --message-body '{"order":"TW-88121","teu":4}' >/dev/null

aws_local iam create-user --user-name orderflow-consumer >/dev/null
aws_local iam put-user-policy --user-name orderflow-consumer --policy-name consumer-access \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "orderflow-consumer is polling orders-prod and getting AccessDenied."
