#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local logs create-log-group --log-group-name /lumen/store-gateway
aws_local iam create-user --user-name lumen-shipper >/dev/null
aws_local iam put-user-policy --user-name lumen-shipper --policy-name lumen-shipper-logs \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "lumen-shipper can create streams but its uploads are denied."
