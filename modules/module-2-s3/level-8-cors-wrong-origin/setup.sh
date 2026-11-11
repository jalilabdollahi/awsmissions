#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

aws_local s3 mb s3://brightcart-media >/dev/null
echo "hero banner" > "$work/hero.txt"
aws_local s3 cp "$work/hero.txt" s3://brightcart-media/banners/hero.jpg >/dev/null

aws_local s3api put-bucket-cors --bucket brightcart-media \
  --cors-configuration "file://$MISSION_DIR/workspace/cors.json"

echo "The admin app's preflights are rejected; the storefront is fine."
