#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local sqs create-queue --queue-name quillon-express-lane >/dev/null
aws_local sqs create-queue --queue-name quillon-standard-lane >/dev/null

aws_local iam create-role --role-name quillon-dispatch-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name quillon-dispatch-role --policy-name lanes \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sqs:SendMessage\",\"Resource\":[\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:quillon-express-lane\",\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:quillon-standard-lane\"]}]}"

aws_local stepfunctions create-state-machine --name quillon-dispatch \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/quillon-dispatch-role" \
  --definition "file://$MISSION_DIR/workspace/dispatch.asl.json" >/dev/null

sm="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:quillon-dispatch"
aws_local stepfunctions start-execution --state-machine-arn "$sm" \
  --input '{"parcelId":"QC-77001","express":true,"kg":2}' >/dev/null
aws_local stepfunctions start-execution --state-machine-arn "$sm" \
  --input '{"parcelId":"QC-77002","kg":5}' >/dev/null

echo "quillon-dispatch is live: express parcels take the slow lane, flagless ones crash."
