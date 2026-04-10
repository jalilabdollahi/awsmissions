#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
sub_arn="$(aws_local sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:000000000000:mission-topic --query 'Subscriptions[0].SubscriptionArn' --output text)"
value="$(aws_local sns get-subscription-attributes --subscription-arn "$sub_arn" --query 'Attributes.FilterPolicy' --output text 2>/dev/null || true)"
[ -z "$value" ] || [ "$value" = "{}" ]
echo "success"
