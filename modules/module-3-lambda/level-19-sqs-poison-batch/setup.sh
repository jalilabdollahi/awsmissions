#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name ticket-ledger \
  --attribute-definitions AttributeName=ticket_id,AttributeType=S \
  --key-schema AttributeName=ticket_id,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null

aws_local sqs create-queue --queue-name ticket-events-dlq >/dev/null
redrive="{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:ticket-events-dlq\",\"maxReceiveCount\":\"3\"}"
attrs="$(jq -cn --arg r "$redrive" '{VisibilityTimeout:"6",RedrivePolicy:$r}')"
aws_local sqs create-queue --queue-name ticket-events --attributes "$attrs" >/dev/null

aws_local iam create-role --role-name ticket-processor-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name ticket-processor-role --policy-name ledger-and-queue \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"dynamodb:UpdateItem\",\"Resource\":\"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/ticket-ledger\"},{\"Effect\":\"Allow\",\"Action\":[\"sqs:ReceiveMessage\",\"sqs:DeleteMessage\",\"sqs:GetQueueAttributes\"],\"Resource\":\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:ticket-events\"}]}"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/processor.zip" processor.py)
aws_local lambda create-function --function-name ticket-processor \
  --runtime python3.12 --handler processor.handler --timeout 15 \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/ticket-processor-role" \
  --zip-file "fileb://$stage/processor.zip" >/dev/null

aws_local lambda create-event-source-mapping --function-name ticket-processor \
  --event-source-arn "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:ticket-events" \
  --batch-size 10 --maximum-batching-window-in-seconds 3 >/dev/null

echo "ticket-processor consumes ticket-events; one bad event poisons the whole batch."
