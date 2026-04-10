#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
url="$(aws_local sqs get-queue-url --queue-name mission-queue --query QueueUrl --output text)"
value="$(aws_local sqs get-queue-attributes --queue-url "$url" --attribute-names VisibilityTimeout --query 'Attributes.VisibilityTimeout' --output text)"
[ "$value" = "60" ]
echo "success"
