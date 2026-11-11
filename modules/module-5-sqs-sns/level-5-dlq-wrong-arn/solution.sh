#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

dlq_url="$(aws_local sqs get-queue-url --queue-name mailroom-outbound-dlq --query QueueUrl --output text)"
real_arn="$(aws_local sqs get-queue-attributes --queue-url "$dlq_url" --attribute-names QueueArn \
  --query Attributes.QueueArn --output text)"

REAL_ARN="$real_arn" python3 - <<'PY'
import json, os
doc = json.load(open("redrive.json"))
policy = json.loads(doc["RedrivePolicy"])
policy["deadLetterTargetArn"] = os.environ["REAL_ARN"]
doc["RedrivePolicy"] = json.dumps(policy)
json.dump(doc, open("redrive.json", "w"), indent=2)
PY

out_url="$(aws_local sqs get-queue-url --queue-name mailroom-outbound --query QueueUrl --output text)"
aws_local sqs set-queue-attributes --queue-url "$out_url" --attributes file://redrive.json
