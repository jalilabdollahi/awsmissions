#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
B=hotline-media

aws_local s3 mb "s3://$B" >/dev/null
echo "PNGDATA autumn banner" > "$work/banner.png"
echo "body { color: #222 }" > "$work/site.css"
echo "PNGDATA 2019 promo" > "$work/old.png"

aws_local s3api put-object --bucket "$B" --key live/autumn-banner.png --body "$work/banner.png" \
  --content-type image/png --metadata campaign=autumn,owner=web --storage-class GLACIER >/dev/null
aws_local s3api put-object --bucket "$B" --key live/site.css --body "$work/site.css" \
  --content-type text/css --metadata owner=web --storage-class GLACIER >/dev/null
aws_local s3api put-object --bucket "$B" --key archive/2019-promo.png --body "$work/old.png" \
  --content-type image/png --metadata campaign=promo2019 --storage-class GLACIER >/dev/null

aws_local s3api put-bucket-lifecycle-configuration --bucket "$B" \
  --lifecycle-configuration "file://$MISSION_DIR/workspace/lifecycle.json"

echo "Live media is stuck in GLACIER and the lifecycle will keep sending it back."
