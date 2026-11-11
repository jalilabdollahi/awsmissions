#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

prod_arn="$(aws_local sqs get-queue-attributes \
  --queue-url "$(aws_local sqs get-queue-url --queue-name orders-prod --query QueueUrl --output text)" \
  --attribute-names QueueArn --query Attributes.QueueArn --output text)"
dlq_arn="$(aws_local sqs get-queue-attributes \
  --queue-url "$(aws_local sqs get-queue-url --queue-name orders-dlq --query QueueUrl --output text)" \
  --attribute-names QueueArn --query Attributes.QueueArn --output text)"

PROD_ARN="$prod_arn" DLQ_ARN="$dlq_arn" python3 - <<'PY'
import json, os
doc = json.load(open("policy.json"))
doc["Statement"][0]["Resource"] = os.environ["PROD_ARN"]
doc["Statement"][1]["Resource"] = os.environ["DLQ_ARN"]
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-user-policy --user-name orderflow-consumer --policy-name consumer-access \
  --policy-document file://policy.json
