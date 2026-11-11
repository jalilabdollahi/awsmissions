#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("checkout.asl.json"))
states = doc["States"]
states["ChargeCard"]["Catch"] = [{
    "ErrorEquals": ["States.ALL"],
    "ResultPath": "$.error",
    "Next": "NotifyDeclined",
}]
states["NotifyDeclined"] = {
    "Type": "Task",
    "Resource": "arn:aws:states:::sqs:sendMessage",
    "Parameters": {
        "QueueUrl": "https://sqs.us-east-1.amazonaws.com/000000000000/pinecrest-declined",
        "MessageBody.$": "States.JsonToString($)",
    },
    "Next": "PaymentFailed",
}
states["PaymentFailed"] = {
    "Type": "Fail",
    "Error": "PaymentFailed",
    "Cause": "The charge was not completed; the customer has been notified.",
}
json.dump(doc, open("checkout.asl.json", "w"), indent=2)
PY

aws_local stepfunctions update-state-machine \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:pinecrest-checkout" \
  --definition file://checkout.asl.json
