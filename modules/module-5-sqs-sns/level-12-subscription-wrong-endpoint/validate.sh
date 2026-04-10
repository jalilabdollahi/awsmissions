#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
endpoint="$(aws_local sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:000000000000:mission-topic --query 'Subscriptions[0].Endpoint' --output text)"
[ "$endpoint" = "arn:aws:sqs:us-east-1:000000000000:mission-queue" ]
echo "success"
