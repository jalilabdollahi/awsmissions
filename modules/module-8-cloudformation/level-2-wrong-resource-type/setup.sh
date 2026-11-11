#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudformation delete-stack --stack-name brightwater-intake >/dev/null 2>&1 || true

aws_local cloudformation create-stack --stack-name brightwater-intake \
  --template-body "file://$MISSION_DIR/workspace/template.yaml" >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name brightwater-intake

echo "brightwater-intake is deployed and reports CREATE_COMPLETE. The front desk disagrees."
