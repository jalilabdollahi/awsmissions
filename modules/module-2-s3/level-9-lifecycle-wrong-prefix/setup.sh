#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
B=ember-app-logs

aws_local s3 mb "s3://$B" >/dev/null
echo "log line" > "$work/l.log"
for key in app-logs/debug/2026-10-01.log app-logs/debug/2026-10-02.log \
           app-logs/error/2026-10-01.log \
           app-logs/audit/2026-q3-admin-actions.log; do
  aws_local s3 cp "$work/l.log" "s3://$B/$key" >/dev/null
done

aws_local s3api put-bucket-lifecycle-configuration --bucket "$B" \
  --lifecycle-configuration "file://$MISSION_DIR/workspace/lifecycle.json"

echo "October's debug logs are still in the bucket despite the lifecycle rules."
