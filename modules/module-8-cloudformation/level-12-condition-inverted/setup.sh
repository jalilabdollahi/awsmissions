#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudformation delete-stack --stack-name marlow-catalog >/dev/null 2>&1 || true
aws_local cloudformation delete-stack --stack-name marlow-condition-probe >/dev/null 2>&1 || true

aws_local cloudformation create-stack --stack-name marlow-catalog \
  --template-body "file://$MISSION_DIR/workspace/template.yaml" \
  --parameters ParameterKey=Environment,ParameterValue=prod >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name marlow-catalog

echo "marlow-catalog (Environment=prod) is deployed and misbehaving."
