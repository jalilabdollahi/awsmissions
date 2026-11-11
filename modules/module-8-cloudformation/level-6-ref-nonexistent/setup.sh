#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudformation delete-stack --stack-name tidewater-manifests >/dev/null 2>&1 || true

aws_local cloudformation create-stack --stack-name tidewater-manifests \
  --template-body "file://$MISSION_DIR/workspace/template.yaml" >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name tidewater-manifests

echo "tidewater-manifests is deployed; the dispatch app still cannot find its bucket."
