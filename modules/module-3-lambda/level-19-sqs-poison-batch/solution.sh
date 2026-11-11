#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

cat > processor.py <<'PY'
import json

import boto3

ddb = boto3.client("dynamodb")


def handler(event, context):
    failures = []
    for record in event["Records"]:
        try:
            ticket = json.loads(record["body"])
            ddb.update_item(
                TableName="ticket-ledger",
                Key={"ticket_id": {"S": ticket["ticket_id"]}},
                UpdateExpression="ADD attempts :one",
                ExpressionAttributeValues={":one": {"N": "1"}},
            )
        except (ValueError, KeyError):
            failures.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failures}
PY

rm -f processor.zip
zip -q processor.zip processor.py
aws_local lambda update-function-code --function-name ticket-processor --zip-file fileb://processor.zip >/dev/null

uuid="$(aws_local lambda list-event-source-mappings --function-name ticket-processor \
  --query 'EventSourceMappings[0].UUID' --output text)"
aws_local lambda update-event-source-mapping --uuid "$uuid" \
  --function-response-types ReportBatchItemFailures >/dev/null
sleep 3
