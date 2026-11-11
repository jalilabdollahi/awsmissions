#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

QUEUE_ARN="arn:aws:sqs:us-east-1:${ACCOUNT_ID}:ember-pager-intake" \
TOPIC_ARN="arn:aws:sns:us-east-1:${ACCOUNT_ID}:ember-alerts" python3 - <<'PY'
import json, os
doc = json.load(open("policy.json"))
st = doc["Statement"][0]
st["Resource"] = os.environ["QUEUE_ARN"]
st["Condition"] = {"ArnEquals": {"aws:SourceArn": os.environ["TOPIC_ARN"]}}
json.dump(doc, open("policy.json", "w"), indent=2)
json.dump({"Policy": json.dumps(doc)}, open("attributes.json", "w"))
PY

url="$(aws_local sqs get-queue-url --queue-name ember-pager-intake --query QueueUrl --output text)"
aws_local sqs set-queue-attributes --queue-url "$url" --attributes file://attributes.json
