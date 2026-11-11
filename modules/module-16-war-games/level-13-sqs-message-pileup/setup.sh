#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
SQS="arn:aws:sqs:us-east-1:${ACCOUNT_ID}"

aws_local sqs create-queue --queue-name pw-sort-jobs-dlq >/dev/null
aws_local sqs create-queue --queue-name pw-ops-pager >/dev/null
TOPIC="$(aws_local sns create-topic --name pw-ops-alerts --query TopicArn --output text)"
aws_local sns subscribe --topic-arn "$TOPIC" --protocol sqs --notification-endpoint "$SQS:pw-ops-pager" >/dev/null

# Typed "from memory": the redrive target is a queue that does not exist, the receive limit is 100,
# and the visibility timeout is a leftover from a load test.
cat > "$tmp/attrs.json" <<JSON
{"VisibilityTimeout":"2","RedrivePolicy":"{\"deadLetterTargetArn\":\"$SQS:pw-sort-dlq\",\"maxReceiveCount\":\"100\"}"}
JSON
aws_local sqs create-queue --queue-name pw-sort-jobs --attributes "file://$tmp/attrs.json" >/dev/null

echo "Ops review item opened: a poison parcel loops forever and nobody gets paged."
