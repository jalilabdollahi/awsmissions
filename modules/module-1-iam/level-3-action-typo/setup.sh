#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for b in lantern-originals lantern-thumbnails; do
  aws_local s3 mb "s3://$b" >/dev/null
done
seed="$(mktemp)"
trap 'rm -f "$seed"' EXIT
printf 'not-really-a-jpeg' > "$seed"
aws_local s3api put-object --bucket lantern-originals --key 2025/10/portrait-0042.jpg --body "$seed" >/dev/null
aws_local s3api put-object --bucket lantern-thumbnails --key 2025/10/portrait-0001.jpg --body "$seed" >/dev/null

aws_local iam create-user --user-name lantern-thumbs >/dev/null
aws_local iam put-user-policy --user-name lantern-thumbs --policy-name thumbnailer \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "lantern-thumbs is deployed. Every resize job dies with AccessDenied."
