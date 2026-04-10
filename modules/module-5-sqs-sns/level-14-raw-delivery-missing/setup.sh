#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local sns create-topic --name mission-topic >/dev/null 2>&1 || true
aws_local sqs create-queue --queue-name mission-queue >/dev/null 2>&1 || true
aws_local sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:mission-topic --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:mission-queue >/dev/null 2>&1 || true
echo "Broken subscription created: raw delivery is disabled"
