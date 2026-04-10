#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ../../../scripts/aws_helpers.sh
aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
aws_local s3api put-bucket-cors --bucket mission-bucket --cors-configuration "file://$SCRIPT_DIR/config.json" >/dev/null
echo "Broken bucket created: mission-bucket (wrong CORS origin)"
