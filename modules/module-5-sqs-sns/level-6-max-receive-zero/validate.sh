#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
url="$(aws_local sqs get-queue-url --queue-name mission-queue --query QueueUrl --output text)"
policy="$(aws_local sqs get-queue-attributes --queue-url "$url" --attribute-names RedrivePolicy --query 'Attributes.RedrivePolicy' --output text)"
case "$policy" in
  *'"maxReceiveCount":"3"'*) echo "success" ;;
  *) exit 1 ;;
esac
