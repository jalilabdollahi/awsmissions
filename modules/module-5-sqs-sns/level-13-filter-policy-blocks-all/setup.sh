#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local sns create-topic --name mission-topic >/dev/null 2>&1 || true
aws_local sqs create-queue --queue-name mission-queue >/dev/null 2>&1 || true
sub_arn="$(aws_local sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:mission-topic --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:mission-queue --query SubscriptionArn --output text)"
aws_local sns set-subscription-attributes --subscription-arn "$sub_arn" --attribute-name FilterPolicy --attribute-value '{"eventType":["nonexistent"]}' >/dev/null
echo "Broken subscription created: filter policy blocks all relevant messages"
