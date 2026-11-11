#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

python3 - "$stage" <<'PY'
import sys, zipfile

ALLOCATE = '''def handler(event, context):
    units = sum(line["qty"] for line in event["items"])
    return {"warehouse": "WH-NORTH" if units <= 5 else "WH-EAST", "units": units}
'''
with zipfile.ZipFile(sys.argv[1] + "/allocate.zip", "w") as z:
    z.writestr("allocate.py", ALLOCATE)
PY

aws_local dynamodb create-table --table-name cedarpoint-fulfilments \
  --attribute-definitions AttributeName=orderId,AttributeType=S \
  --key-schema AttributeName=orderId,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null

aws_local iam create-role --role-name cedarpoint-lambda-exec \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name cedarpoint-allocate-stock --runtime python3.12 \
  --handler allocate.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/cedarpoint-lambda-exec" \
  --zip-file "fileb://$stage/allocate.zip" >/dev/null
aws_local lambda invoke --function-name cedarpoint-allocate-stock --cli-binary-format raw-in-base64-out \
  --payload '{"items":[{"sku":"warm","qty":1}]}' /dev/null >/dev/null

# The workflow's own role.
aws_local iam create-role --role-name cedarpoint-fulfilment-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name cedarpoint-fulfilment-role --policy-name fulfilment \
  --policy-document "file://$MISSION_DIR/workspace/workflow-role-policy.json"

# The role EventBridge uses to start executions.
aws_local iam create-role --role-name cedarpoint-events-invoke-sfn \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"events.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name cedarpoint-events-invoke-sfn --policy-name start-executions \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"states:StartExecution\",\"Resource\":\"arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:cedarpoint-fulfilment*\"}]}"

role="arn:aws:iam::${ACCOUNT_ID}:role/cedarpoint-fulfilment-role"
aws_local stepfunctions create-state-machine --name cedarpoint-fulfilment --role-arn "$role" \
  --definition "file://$MISSION_DIR/workspace/fulfilment.asl.json" >/dev/null
# The pre-migration workflow nobody deleted: it accepts any input and does nothing useful.
aws_local stepfunctions create-state-machine --name cedarpoint-fulfilment-legacy --role-arn "$role" \
  --definition '{"Comment":"retired after the migration","StartAt":"Noop","States":{"Noop":{"Type":"Pass","End":true}}}' >/dev/null

aws_local events put-rule --name cedarpoint-order-placed \
  --event-pattern "file://$MISSION_DIR/workspace/order-placed-pattern.json" >/dev/null
aws_local events put-targets --rule cedarpoint-order-placed \
  --targets "file://$MISSION_DIR/workspace/rule-targets.json" >/dev/null

echo "The rule, the workflow and the table exist; orders never reach the table."
