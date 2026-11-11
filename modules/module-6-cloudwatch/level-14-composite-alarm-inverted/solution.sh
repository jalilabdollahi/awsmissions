#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

printf '%s\n' 'ALARM("strata-api-errors") OR ALARM("strata-api-latency")' > alarm-rule.txt
aws_local cloudwatch put-composite-alarm --alarm-name strata-api-unhealthy \
  --alarm-rule "$(cat alarm-rule.txt)" \
  --alarm-actions "arn:aws:sns:us-east-1:${ACCOUNT_ID}:strata-oncall"
