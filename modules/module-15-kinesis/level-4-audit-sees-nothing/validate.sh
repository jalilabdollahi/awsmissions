#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# A swipe that arrives "tonight": the audit must see it as well.
probe="sw-probe-$(date +%s)"
aws_local kinesis put-record --stream-name card-swipes --partition-key "card-probe" \
  --data "$(printf '{"swipe_id":"%s","cents":100}' "$probe" | base64)" >/dev/null

out="$(mktemp)"
trap 'rm -f "$out" "$out.meta"' EXIT
aws_local lambda invoke --function-name swipe-audit --cli-binary-format raw-in-base64-out \
  --payload '{}' "$out" > "$out.meta" 2>&1 || true
if grep -q FunctionError "$out.meta"; then
  echo "swipe-audit crashed: $(jq -r '.errorMessage // "unknown error"' "$out")"
  exit 1
fi

audited="$(jq -r '.audited' "$out")"
if [ "$audited" = "0" ]; then
  echo "swipe-audit finished cleanly but audited 0 swipes while card-swipes holds at least 7 records right now."
  exit 1
fi
missing=""
for id in sw-1001 sw-1002 sw-1003 sw-1004 sw-1005 sw-1006 "$probe"; do
  if ! jq -e --arg id "$id" '.swipe_ids | index($id) != null' "$out" >/dev/null; then
    missing="$missing $id"
  fi
done
if [ -n "$missing" ]; then
  echo "swipe-audit saw $audited swipe(s) but is missing:$missing. It must cover everything the stream still retains."
  exit 1
fi
total="$(jq -r '.total_cents' "$out")"
if [ "$total" -lt 22204 ]; then
  echo "swipe-audit found the swipes but its total ($total cents) is lower than what the stream holds."
  exit 1
fi

echo "swipe-audit audited $audited swipes, including the one that just arrived (total $total cents)."
