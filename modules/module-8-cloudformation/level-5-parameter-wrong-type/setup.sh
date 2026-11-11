#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudformation delete-stack --stack-name quarry-resizer >/dev/null 2>&1 || true

# The pipeline's first (failed) run, using the files in the workspace.
set +e
aws_local cloudformation create-stack --stack-name quarry-resizer \
  --template-body "file://$MISSION_DIR/workspace/template.yaml" \
  --parameters "file://$MISSION_DIR/workspace/params.json" >/dev/null
set -e

wait_for "quarry-resizer to settle" 30 sh -c \
  "aws --endpoint-url=$AWS_ENDPOINT_URL cloudformation describe-stacks --stack-name quarry-resizer --query 'Stacks[0].StackStatus' --output text | grep -q ROLLBACK_COMPLETE"

echo "The release run left quarry-resizer in ROLLBACK_COMPLETE."
