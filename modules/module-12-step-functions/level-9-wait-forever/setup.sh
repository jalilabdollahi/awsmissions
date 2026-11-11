#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local sqs create-queue --queue-name halcyon-reminders >/dev/null

aws_local iam create-role --role-name halcyon-reminder-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name halcyon-reminder-role --policy-name reminders \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sqs:SendMessage\",\"Resource\":\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:halcyon-reminders\"}]}"

aws_local stepfunctions create-state-machine --name halcyon-trial-reminder \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/halcyon-reminder-role" \
  --definition "file://$MISSION_DIR/workspace/trial-reminder.asl.json" >/dev/null

# A 14-day trial customer signed up yesterday; their execution is waiting.
due="$(python3 -c 'import datetime as d; print((d.datetime.now(d.timezone.utc)+d.timedelta(days=13)).strftime("%Y-%m-%dT%H:%M:%SZ"))')"
aws_local stepfunctions start-execution \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:halcyon-trial-reminder" \
  --input "{\"accountId\":\"ACME-114\",\"remindAt\":\"$due\"}" >/dev/null

echo "halcyon-trial-reminder is live and every execution waits one week, whatever remindAt says."
