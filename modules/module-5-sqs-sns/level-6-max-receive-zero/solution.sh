#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("redrive.json"))
policy = json.loads(doc["RedrivePolicy"])
policy["maxReceiveCount"] = "5"
doc["RedrivePolicy"] = json.dumps(policy)
json.dump(doc, open("redrive.json", "w"), indent=2)
PY

url="$(aws_local sqs get-queue-url --queue-name pinecrest-sms --query QueueUrl --output text)"
aws_local sqs set-queue-attributes --queue-url "$url" --attributes file://redrive.json
