#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("manifest-import.asl.json"))
each = doc["States"]["EachParcel"]
each["ItemSelector"]["batchId.$"] = "$.batchId"
inner = each["ItemProcessor"]["States"]
inner["ValidateParcel"]["Catch"] = [{
    "ErrorEquals": ["MalformedParcel"],
    "ResultPath": "$.error",
    "Next": "Quarantine",
}]
inner["Quarantine"] = {
    "Type": "Task",
    "Resource": "arn:aws:states:::sqs:sendMessage",
    "Parameters": {
        "QueueUrl": "https://sqs.us-east-1.amazonaws.com/000000000000/kestrel-quarantine",
        "MessageBody": {
            "batchId.$": "$.batchId",
            "parcelId.$": "$.parcel.id",
            "reason.$": "$.error.Error",
            "detail.$": "$.error.Cause",
        },
    },
    "End": True,
}
json.dump(doc, open("manifest-import.asl.json", "w"), indent=2)
PY

aws_local stepfunctions update-state-machine \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:kestrel-manifest-import" \
  --definition file://manifest-import.asl.json
