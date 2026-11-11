#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for q in bw-pager bw-escalations bw-backlog; do
  aws_local sqs create-queue --queue-name "$q" >/dev/null
done

aws_local iam create-role --role-name brightwave-triage-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name brightwave-triage-role --policy-name send-to-queues \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sqs:SendMessage\",\"Resource\":\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:bw-*\"}]}"

aws_local stepfunctions create-state-machine --name brightwave-ticket-triage \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/brightwave-triage-role" \
  --definition "file://$MISSION_DIR/workspace/triage.asl.json" >/dev/null

# A few "low" tickets already failed this morning.
sm="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:brightwave-ticket-triage"
for n in 4401 4402; do
  aws_local stepfunctions start-execution --state-machine-arn "$sm" \
    --input "{\"ticketId\":\"T-$n\",\"priority\":\"low\"}" >/dev/null
done

echo "Triage is live: urgent and high tickets flow, a low ticket fails."
