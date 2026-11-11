#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

aws_local s3 mb s3://tidewater-pod-photos >/dev/null
echo "photo bytes" > "$work/pod.txt"
aws_local s3 cp "$work/pod.txt" s3://tidewater-pod-photos/pod/shipment-88213.jpg >/dev/null

# Deliberately no CORS configuration on the bucket.
echo "Browser uploads from the dashboard are blocked by CORS."
