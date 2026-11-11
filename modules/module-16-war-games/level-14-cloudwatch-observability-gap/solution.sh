#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. Filter on the right log group with the field the function really logs.
aws_local logs put-metric-filter --log-group-name /aws/lambda/tf-checkout-fn --filter-name checkout-errors \
  --filter-pattern '{ $.level = "ERROR" }' \
  --metric-transformations metricName=CheckoutFailures,metricNamespace=TF/Checkout,metricValue=1
aws_local logs delete-metric-filter --log-group-name /aws/lambda/tf-checkout-fn-old --filter-name checkout-errors

# 2. Alarm: same alarm, production paging topic.
aws_local cloudwatch put-metric-alarm --alarm-name tf-checkout-errors \
  --namespace TF/Checkout --metric-name CheckoutFailures --statistic Sum \
  --period 10 --evaluation-periods 1 --threshold 5 --comparison-operator GreaterThanOrEqualToThreshold \
  --treat-missing-data notBreaching --alarm-actions "arn:aws:sns:us-east-1:${ACCOUNT_ID}:tf-oncall"
