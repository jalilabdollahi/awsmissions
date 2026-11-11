#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
QARN="arn:aws:sqs:us-east-1:${ACCOUNT_ID}:tt-ticket-fulfilment"

aws_local dynamodb create-table --table-name tt-fulfilled-tickets \
  --attribute-definitions AttributeName=ticketId,AttributeType=S \
  --key-schema AttributeName=ticketId,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null
aws_local sqs create-queue --queue-name tt-ticket-fulfilment \
  --attributes VisibilityTimeout=8 >/dev/null
TOPIC="$(aws_local sns create-topic --name tt-ticket-events --query TopicArn --output text)"

# Subscription: still filtering on the pre-rename event name, still wrapped in the SNS envelope.
aws_local sns subscribe --topic-arn "$TOPIC" --protocol sqs --notification-endpoint "$QARN" \
  --attributes '{"FilterPolicy":"{\"eventType\":[\"TicketPurchased\"]}","RawMessageDelivery":"false"}' >/dev/null

aws_local iam create-role --role-name tt-fulfiller-role --assume-role-policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name tt-fulfiller-role --policy-name fulfil --policy-document "{
  \"Version\":\"2012-10-17\",\"Statement\":[
   {\"Effect\":\"Allow\",\"Action\":[\"sqs:ReceiveMessage\",\"sqs:DeleteMessage\",\"sqs:GetQueueAttributes\"],\"Resource\":\"$QARN\"},
   {\"Effect\":\"Allow\",\"Action\":\"dynamodb:PutItem\",\"Resource\":\"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/tt-fulfilled-tickets\"}]}"

cat > "$work/fulfil.py" <<'PY'
import json
import os
import boto3

table = os.environ["TABLE_NAME"]

def handler(event, context):
    ddb = boto3.client("dynamodb")
    for record in event["Records"]:
        ticket = json.loads(record["body"])
        ddb.put_item(TableName=table, Item={
            "ticketId": {"S": ticket["ticketId"]},
            "seat": {"S": ticket["seat"]},
        })
    return {"fulfilled": len(event["Records"])}
PY
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],'fulfil.py')" "$work/f.zip" "$work/fulfil.py"
aws_local lambda create-function --function-name tt-ticket-fulfiller --runtime python3.12 \
  --handler fulfil.handler --timeout 10 --role "arn:aws:iam::${ACCOUNT_ID}:role/tt-fulfiller-role" \
  --zip-file "fileb://$work/f.zip" --environment 'Variables={TABLE_NAME=tt-fulfilled-tickets}' >/dev/null
aws_local lambda wait function-active-v2 --function-name tt-ticket-fulfiller 2>/dev/null || sleep 3

# "Tidying" before the freeze: mapping switched off and the function throttled to nothing.
uuid="$(aws_local lambda create-event-source-mapping --function-name tt-ticket-fulfiller \
  --event-source-arn "$QARN" --batch-size 1 --query UUID --output text)"
aws_local lambda update-event-source-mapping --uuid "$uuid" --no-enabled >/dev/null
aws_local lambda put-function-concurrency --function-name tt-ticket-fulfiller --reserved-concurrent-executions 0 >/dev/null

echo "TT-5530 is open: tickets are sold, nothing is fulfilled."
