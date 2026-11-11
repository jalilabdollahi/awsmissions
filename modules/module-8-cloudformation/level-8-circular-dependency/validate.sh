#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TOPIC_ARN="arn:aws:sns:us-east-1:${ACCOUNT_ID}:granitepeak-upload-events"
status="$(aws_local cloudformation describe-stacks --stack-name granitepeak-intake \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
case "$status" in
  CREATE_COMPLETE|UPDATE_COMPLETE) ;;
  "") echo "There is no stack named granitepeak-intake yet. Deploy the template under that name and read any error."; exit 1 ;;
  *) echo "granitepeak-intake is in $status."; exit 1 ;;
esac

policy="$(aws_local sns get-topic-attributes --topic-arn "$TOPIC_ARN" \
  --query 'Attributes.Policy' --output text 2>/dev/null || true)"
if [ -z "$policy" ] || [ "$policy" = "None" ]; then
  echo "The topic granitepeak-upload-events has no access policy. Keep the publish restriction in the stack."
  exit 1
fi
if ! printf '%s' "$policy" | jq -e '.Statement[] | select(.Principal.Service=="s3.amazonaws.com") | .Condition | tostring | contains("arn:aws:s3:::granitepeak-uploads")' >/dev/null 2>&1; then
  echo "The topic policy must still limit publishing to the bucket arn:aws:s3:::granitepeak-uploads (an aws:SourceArn condition)."
  exit 1
fi

# End to end: subscribe a probe queue, upload a file, expect a notification.
probe_queue="granitepeak-probe-$$"
queue_url="$(aws_local sqs create-queue --queue-name "$probe_queue" --query QueueUrl --output text)"
cleanup() { aws_local sqs delete-queue --queue-url "$queue_url" >/dev/null 2>&1 || true; }
trap cleanup EXIT
aws_local sns subscribe --topic-arn "$TOPIC_ARN" --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:${probe_queue}" >/dev/null

probe_file="$(mktemp)"
trap 'cleanup; rm -f "$probe_file"' EXIT
echo "clip" > "$probe_file"
if ! aws_local s3api put-object --bucket granitepeak-uploads --key clips/validate.txt --body "$probe_file" >/dev/null 2>&1; then
  echo "Could not upload to granitepeak-uploads; does the bucket exist?"
  exit 1
fi

body="$(aws_local sqs receive-message --queue-url "$queue_url" --wait-time-seconds 5 \
  --query 'Messages[0].Body' --output text 2>/dev/null || true)"
case "$body" in
  *granitepeak-uploads*) ;;
  *) echo "Uploaded a file but no notification reached the topic's subscriber. The bucket's notification setup is missing."; exit 1 ;;
esac

echo "Uploads to granitepeak-uploads now announce themselves on granitepeak-upload-events, still restricted to that bucket."
