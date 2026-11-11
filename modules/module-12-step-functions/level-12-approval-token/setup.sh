#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for q in brightline-approvals brightline-issued brightline-requester-notices; do
  aws_local sqs create-queue --queue-name "$q" >/dev/null
done

aws_local iam create-role --role-name brightline-po-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name brightline-po-role --policy-name po-queues \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sqs:SendMessage\",\"Resource\":\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:brightline-*\"}]}"

aws_local stepfunctions create-state-machine --name brightline-po-approval \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/brightline-po-role" \
  --definition "file://$MISSION_DIR/workspace/po-approval.asl.json" >/dev/null

# A request from this morning is still waiting for a manager who cannot answer it.
aws_local stepfunctions start-execution \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:brightline-po-approval" \
  --input '{"poId":"PO-5001","amount":12400,"requester":"sam.keller"}' >/dev/null

echo "brightline-po-approval is live: requests go out, but nobody can answer them."
