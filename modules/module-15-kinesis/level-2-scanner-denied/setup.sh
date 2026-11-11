#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for stream in parcel-scans parcel-scans-staging parcel-billing; do
  aws_local kinesis create-stream --stream-name "$stream" --shard-count 1 >/dev/null
done

aws_local iam create-user --user-name scan-gateway >/dev/null
aws_local iam put-user-policy --user-name scan-gateway --policy-name depot-publish \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "Three streams exist; scan-gateway holds a policy copied from staging."
