#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

python3 - "$stage" <<'PY'
import sys, zipfile

SCORER = '''def handler(event, context):
    total = sum(i["qty"] * i["unitPrice"] for i in event["items"])
    score = min(99, int(total / 50))
    if event["customer"]["accountAgeDays"] < 30:
        score += 25
    return {"riskScore": score, "model": "lumen-fs-7"}
'''
with zipfile.ZipFile(sys.argv[1] + "/scorer.zip", "w") as z:
    z.writestr("scorer.py", SCORER)
PY

aws_local sqs create-queue --queue-name lumen-review-desk >/dev/null

aws_local iam create-role --role-name lumen-scorer-exec \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name lumen-fraud-score --runtime python3.12 \
  --handler scorer.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/lumen-scorer-exec" \
  --zip-file "fileb://$stage/scorer.zip" >/dev/null

aws_local iam create-role --role-name lumen-screening-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name lumen-screening-role --policy-name screening \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"lambda:InvokeFunction\",\"Resource\":\"arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:lumen-fraud-score\"},{\"Effect\":\"Allow\",\"Action\":\"sqs:SendMessage\",\"Resource\":\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:lumen-review-desk\"}]}"

aws_local stepfunctions create-state-machine --name lumen-order-screening \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/lumen-screening-role" \
  --definition "file://$MISSION_DIR/workspace/order-screening.asl.json" >/dev/null

# Yesterday's order already went through the broken flow.
aws_local stepfunctions start-execution \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:lumen-order-screening" \
  --input '{"orderId":"LW-90001","customer":{"name":"Kestrel Hardware","accountAgeDays":400},"items":[{"sku":"BRK-12","qty":10,"unitPrice":42}]}' >/dev/null

echo "lumen-order-screening is live; the review desk only receives bare scores."
