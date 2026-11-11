#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("po-approval.asl.json"))
states = doc["States"]
ask = states["AskManager"]
body = ask["Parameters"]["MessageBody"]
del body["taskToken"]
body["taskToken.$"] = "$$.Task.Token"
ask["ResultPath"] = "$.approval"
ask["Catch"] = [{
    "ErrorEquals": ["Rejected"],
    "ResultPath": "$.rejection",
    "Next": "TellRequester",
}]
states["TellRequester"] = {
    "Type": "Task",
    "Resource": "arn:aws:states:::sqs:sendMessage",
    "Parameters": {
        "QueueUrl": "https://sqs.us-east-1.amazonaws.com/000000000000/brightline-requester-notices",
        "MessageBody": {
            "poId.$": "$.poId",
            "requester.$": "$.requester",
            "outcome": "REJECTED",
            "reason.$": "$.rejection.Cause",
        },
    },
    "End": True,
}
json.dump(doc, open("po-approval.asl.json", "w"), indent=2)
PY

aws_local stepfunctions update-state-machine \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:brightline-po-approval" \
  --definition file://po-approval.asl.json
