#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

latest="$(aws_local lambda list-layer-versions --layer-name riskkit-core \
  --query 'max_by(LayerVersions, &Version).LayerVersionArn' --output text)"
aws_local lambda update-function-configuration --function-name txn-scorer \
  --layers "$latest" "arn:aws:lambda:us-east-1:${ACCOUNT_ID}:layer:tracekit-logging:1" >/dev/null
