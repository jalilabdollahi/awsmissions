#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local sqs create-queue --queue-name mission-queue >/dev/null 2>&1 || true
aws_local sqs create-queue --queue-name mission-dlq >/dev/null 2>&1 || true
url="$(aws_local sqs get-queue-url --queue-name mission-queue --query QueueUrl --output text)"
aws_local sqs set-queue-attributes --queue-url "$url" --attributes RedrivePolicy='{"deadLetterTargetArn":"arn:aws:sqs:us-east-1:000000000000:wrong-dlq","maxReceiveCount":"3"}' >/dev/null
echo "Broken queue created: redrive policy points to wrong-dlq"
