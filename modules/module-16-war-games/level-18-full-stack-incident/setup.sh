#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
SQS="arn:aws:sqs:us-east-1:${ACCOUNT_ID}"
TRUST='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

aws_local sqs create-queue --queue-name ns-order-queue --attributes VisibilityTimeout=15 >/dev/null
aws_local sqs create-queue --queue-name ns-payments-queue >/dev/null
# The re-created table: camelCase naming standard, but the key attribute is still snake_case.
aws_local dynamodb create-table --table-name ns-orders --attribute-definitions AttributeName=order_id,AttributeType=S \
  --key-schema AttributeName=order_id,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null
aws_local dynamodb put-item --table-name ns-orders --item '{"order_id":{"S":"o-legacy-1"},"sku":{"S":"mug-red"}}' >/dev/null

cat > "$tmp/intake.py" <<'PY'
import json
import os
import boto3

def handler(event, context):
    order = json.loads(event["body"])
    try:
        boto3.client("sqs").send_message(QueueUrl=os.environ["QUEUE_URL"], MessageBody=json.dumps(order))
    except Exception as exc:  # fire and forget: the storefront must never wait on the queue
        print("enqueue failed:", exc)
    return {"statusCode": 202, "body": json.dumps({"accepted": order["orderId"]})}
PY
cat > "$tmp/writer.py" <<'PY'
import json
import boto3

def handler(event, context):
    ddb = boto3.client("dynamodb")
    for rec in event["Records"]:
        order = json.loads(rec["body"])
        if order.get("probe"):
            continue
        ddb.put_item(TableName="ns-orders", Item={"orderId": {"S": order["orderId"]}, "sku": {"S": order["sku"]}})
    return {"written": len(event["Records"])}
PY
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],sys.argv[3])" "$tmp/intake.zip" "$tmp/intake.py" intake.py
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],sys.argv[3])" "$tmp/writer.zip" "$tmp/writer.py" writer.py

aws_local iam create-user --user-name ns-oncall >/dev/null
aws_local iam put-user-policy --user-name ns-oncall --policy-name assume-intake --policy-document \
  "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::${ACCOUNT_ID}:role/ns-intake-role\"}]}"
aws_local iam create-role --role-name ns-intake-role --assume-role-policy-document "{
  \"Version\":\"2012-10-17\",\"Statement\":[
   {\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"},
   {\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::${ACCOUNT_ID}:user/ns-oncall\"},\"Action\":\"sts:AssumeRole\"}]}" >/dev/null
# "Least privilege": the intake role was given nothing for SQS at all.
aws_local iam put-role-policy --role-name ns-intake-role --policy-name intake --policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["logs:CreateLogGroup","logs:PutLogEvents"],"Resource":"*"}]}'
aws_local iam create-role --role-name ns-writer-role --assume-role-policy-document "$TRUST" >/dev/null
aws_local iam put-role-policy --role-name ns-writer-role --policy-name writer --policy-document "{
  \"Version\":\"2012-10-17\",\"Statement\":[
   {\"Effect\":\"Allow\",\"Action\":[\"sqs:ReceiveMessage\",\"sqs:DeleteMessage\",\"sqs:GetQueueAttributes\"],\"Resource\":\"$SQS:ns-order-queue\"},
   {\"Effect\":\"Allow\",\"Action\":\"dynamodb:PutItem\",\"Resource\":\"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/ns-orders\"}]}"

# The stale template points at the old queue name.
aws_local lambda create-function --function-name ns-order-intake --runtime python3.12 --handler intake.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/ns-intake-role" --zip-file "fileb://$tmp/intake.zip" \
  --environment "Variables={QUEUE_URL=$AWS_ENDPOINT_URL/${ACCOUNT_ID}/ns-orders-queue}" >/dev/null
aws_local lambda create-function --function-name ns-order-writer --runtime python3.12 --handler writer.handler \
  --timeout 10 --role "arn:aws:iam::${ACCOUNT_ID}:role/ns-writer-role" --zip-file "fileb://$tmp/writer.zip" >/dev/null
aws_local lambda wait function-active-v2 --function-name ns-order-writer 2>/dev/null || sleep 2
aws_local lambda create-event-source-mapping --function-name ns-order-writer --event-source-arn "$SQS:ns-order-queue" \
  --batch-size 1 >/dev/null
aws_local lambda put-function-concurrency --function-name ns-order-writer --reserved-concurrent-executions 0 >/dev/null

API="$(aws_local apigateway create-rest-api --name ns-orders-api --query id --output text)"
ROOT="$(aws_local apigateway get-resources --rest-api-id "$API" --query 'items[0].id' --output text)"
RES="$(aws_local apigateway create-resource --rest-api-id "$API" --parent-id "$ROOT" --path-part orders --query id --output text)"
aws_local apigateway put-method --rest-api-id "$API" --resource-id "$RES" --http-method POST --authorization-type NONE >/dev/null
aws_local apigateway put-integration --rest-api-id "$API" --resource-id "$RES" --http-method POST --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:ns-order-intake/invocations" >/dev/null
aws_local apigateway create-deployment --rest-api-id "$API" --stage-name v1 >/dev/null

echo "INC-8830 is open: orders are accepted and then vanish."
