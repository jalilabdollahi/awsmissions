#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic="$(aws_local sns create-topic --name cobalt-order-events --query TopicArn --output text)"
aws_local sqs create-queue --queue-name cobalt-refund-worker >/dev/null

# The filter as the refund team wrote it (see workspace/filter.json).
attrs="$(mktemp)"
python3 -c 'import json,sys; print(json.dumps({"FilterPolicy": json.dumps(json.load(open(sys.argv[1])))}))' \
  "$MISSION_DIR/workspace/filter.json" > "$attrs"
aws_local sns subscribe --topic-arn "$topic" --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:cobalt-refund-worker" \
  --attributes "file://$attrs" >/dev/null
rm -f "$attrs"

echo "cobalt-refund-worker is subscribed with a filter on eventType, and gets nothing."
