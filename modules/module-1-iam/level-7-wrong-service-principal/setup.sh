#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

queue_url="$(aws_local sqs create-queue --queue-name payments-retry --query QueueUrl --output text)"
aws_local sqs send-message --queue-url "$queue_url" --message-body '{"payment":"stuck-1"}' >/dev/null
aws_local sqs send-message --queue-url "$queue_url" --message-body '{"payment":"stuck-2"}' >/dev/null

for u in sre-oncall sre-intern; do
  aws_local iam create-user --user-name "$u" >/dev/null
  aws_local iam put-user-policy --user-name "$u" --policy-name assume-any-role \
    --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"sts:AssumeRole","Resource":"*"}]}'
done

aws_local iam create-role --role-name sre-breakglass \
  --assume-role-policy-document "file://$MISSION_DIR/workspace/trust-policy.json" >/dev/null
aws_local iam put-role-policy --role-name sre-breakglass --policy-name purge-retry-queue \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"sqs:PurgeQueue\",\"sqs:GetQueueAttributes\"],\"Resource\":\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:payments-retry\"}]}"

echo "sre-breakglass is ready for the next incident, if anyone can assume it."
