#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
count="$(aws_local sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:000000000000:mission-topic --query 'length(Subscriptions)' --output text)"
[ "$count" -ge 1 ]
echo "success"
