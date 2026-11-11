#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

dlq_url="$(aws_local sqs create-queue --queue-name ledgerlink-settlements-dlq \
  --attributes MessageRetentionPeriod=1209600 --query QueueUrl --output text)"
dlq_arn="$(aws_local sqs get-queue-attributes --queue-url "$dlq_url" --attribute-names QueueArn \
  --query Attributes.QueueArn --output text)"

DLQ_ARN="$dlq_arn" python3 - <<'PY'
import os
text = open("redrive.json").read()
text = text.replace("FILL_IN_DLQ_ARN", os.environ["DLQ_ARN"]).replace("FILL_IN_NUMBER", "4")
open("redrive.json", "w").write(text)
PY

src_url="$(aws_local sqs get-queue-url --queue-name ledgerlink-settlements --query QueueUrl --output text)"
aws_local sqs set-queue-attributes --queue-url "$src_url" --attributes file://redrive.json
