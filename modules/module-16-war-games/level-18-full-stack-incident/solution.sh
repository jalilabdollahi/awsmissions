#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. Intake: the real queue.
aws_local lambda update-function-configuration --function-name ns-order-intake \
  --environment "Variables={QUEUE_URL=$AWS_ENDPOINT_URL/${ACCOUNT_ID}/ns-order-queue}" >/dev/null
aws_local lambda wait function-updated-v2 --function-name ns-order-intake 2>/dev/null || sleep 2

# 2. Intake role: SendMessage on the order queue only.
aws_local iam put-role-policy --role-name ns-intake-role --policy-name intake --policy-document '{
  "Version":"2012-10-17","Statement":[
   {"Effect":"Allow","Action":["logs:CreateLogGroup","logs:PutLogEvents"],"Resource":"*"},
   {"Effect":"Allow","Action":"sqs:SendMessage","Resource":"arn:aws:sqs:us-east-1:000000000000:ns-order-queue"}]}'

# 3. Un-park the writer.
aws_local lambda delete-function-concurrency --function-name ns-order-writer

# 4. Re-create the table with the key the writer uses, keeping the ledger rows (renamed key attribute).
aws_local dynamodb scan --table-name ns-orders --output json > old-orders.json
aws_local dynamodb delete-table --table-name ns-orders >/dev/null
gone() { ! aws_local dynamodb describe-table --table-name ns-orders >/dev/null 2>&1; }
wait_for "old table to disappear" 20 gone
aws_local dynamodb create-table --table-name ns-orders --attribute-definitions AttributeName=orderId,AttributeType=S \
  --key-schema AttributeName=orderId,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null
python3 - <<'PY'
import json, subprocess, os
for item in json.load(open("old-orders.json"))["Items"]:
    item["orderId"] = item.pop("order_id")
    subprocess.run(["aws", "--endpoint-url", os.environ["AWS_ENDPOINT_URL"], "dynamodb", "put-item",
                    "--table-name", "ns-orders", "--item", json.dumps(item)], check=True, stdout=subprocess.DEVNULL)
PY
