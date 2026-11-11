#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local sqs create-queue --queue-name sms-failed-deliveries >/dev/null

aws_local iam create-role --role-name sms-notifier-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name sms-notifier-role --policy-name failure-queue-and-logs \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sqs:SendMessage\",\"Resource\":\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:sms-failed-deliveries\"},{\"Effect\":\"Allow\",\"Action\":[\"logs:CreateLogGroup\",\"logs:CreateLogStream\",\"logs:PutLogEvents\"],\"Resource\":\"*\"}]}"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/notify.zip" notify.py)
aws_local lambda create-function --function-name sms-notifier \
  --runtime python3.12 --handler notify.send \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/sms-notifier-role" \
  --zip-file "fileb://$stage/notify.zip" >/dev/null

# Retries are off on purpose; nothing says what to do with failures.
aws_local lambda put-function-event-invoke-config --function-name sms-notifier \
  --maximum-retry-attempts 0 --maximum-event-age-in-seconds 3600 >/dev/null

echo "sms-notifier runs asynchronously with no retries and no place for failures to go."
