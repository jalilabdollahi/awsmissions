#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

python3 - "$stage" <<'PY'
import sys, zipfile

CHARGE = '''class CardDeclined(Exception):
    pass


def handler(event, context):
    card = event["cardToken"]
    if card == "tok_declined":
        raise CardDeclined("issuer refused the charge: insufficient funds")
    if card == "tok_gateway_down":
        raise RuntimeError("payment gateway unreachable")
    return {"chargeId": "ch_" + event["orderId"], "amount": event["amount"]}
'''
with zipfile.ZipFile(sys.argv[1] + "/charge.zip", "w") as z:
    z.writestr("charge.py", CHARGE)
PY

aws_local sqs create-queue --queue-name pinecrest-receipts >/dev/null
aws_local sqs create-queue --queue-name pinecrest-declined >/dev/null

aws_local iam create-role --role-name pinecrest-lambda-exec \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name pinecrest-charge-card --runtime python3.12 \
  --handler charge.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/pinecrest-lambda-exec" \
  --zip-file "fileb://$stage/charge.zip" >/dev/null

aws_local iam create-role --role-name pinecrest-checkout-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name pinecrest-checkout-role --policy-name checkout \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"lambda:InvokeFunction\",\"Resource\":\"arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:pinecrest-charge-card\"},{\"Effect\":\"Allow\",\"Action\":\"sqs:SendMessage\",\"Resource\":[\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:pinecrest-receipts\",\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:pinecrest-declined\"]}]}"

aws_local stepfunctions create-state-machine --name pinecrest-checkout \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/pinecrest-checkout-role" \
  --definition "file://$MISSION_DIR/workspace/checkout.asl.json" >/dev/null

aws_local lambda invoke --function-name pinecrest-charge-card --cli-binary-format raw-in-base64-out \
  --payload '{"orderId":"warm","cardToken":"tok_ok","amount":1}' /dev/null >/dev/null

# One declined order already slipped through as a "success".
aws_local stepfunctions start-execution \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:pinecrest-checkout" \
  --input '{"orderId":"PT-30011","cardToken":"tok_declined","amount":8800}' >/dev/null

echo "pinecrest-checkout reports SUCCEEDED even for declined cards."
