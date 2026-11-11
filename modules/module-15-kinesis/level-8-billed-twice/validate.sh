#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# A self-contained scenario, so the real ledger is never touched and the check can be repeated:
# event A was billed by the previous run (the checkpoint names it), B and C are new.
run="$(date +%s)"
put() {
  aws_local kinesis put-record --stream-name usage-events --partition-key "probe-$1" \
    --data "$(printf '{"event_id":"%s-%s","mb":1}' "$1" "$run" | base64)" --query SequenceNumber --output text
}
seq_a="$(put pa)"
put pb >/dev/null
seq_c="$(put pc)"
aws_local dynamodb put-item --table-name invoice-lines \
  --item "{\"event_id\":{\"S\":\"pa-$run\"},\"times_billed\":{\"N\":\"1\"}}" >/dev/null
aws_local ssm put-parameter --name /brightline/billing/checkpoint --type String --value "$seq_a" --overwrite >/dev/null

out="$(mktemp)"
trap 'rm -f "$out" "$out.meta"' EXIT
aws_local lambda invoke --function-name billing-resume --cli-binary-format raw-in-base64-out \
  --payload '{}' "$out" > "$out.meta" 2>&1 || true
if grep -q FunctionError "$out.meta"; then
  echo "billing-resume crashed: $(jq -r '.errorMessage // "unknown error"' "$out")"
  exit 1
fi

times() {
  aws_local dynamodb get-item --table-name invoice-lines --key "{\"event_id\":{\"S\":\"$1-$run\"}}" \
    --query 'Item.times_billed.N' --output text 2>/dev/null || true
}
a="$(times pa)"; b="$(times pb)"; c="$(times pc)"
if [ "$a" != "1" ]; then
  echo "The event the checkpoint pointed at was billed again (it now has times_billed=$a). The checkpoint names an event that is already done."
  exit 1
fi
if [ "$b" != "1" ] || [ "$c" != "1" ]; then
  echo "The events after the checkpoint were not billed exactly once (second event: '$b', third event: '$c')."
  exit 1
fi
saved="$(aws_local ssm get-parameter --name /brightline/billing/checkpoint --query Parameter.Value --output text)"
if [ "$saved" != "$seq_c" ]; then
  echo "The checkpoint did not advance to the last event that was billed."
  exit 1
fi

echo "billing-resume skipped the already-billed event, billed the two new ones once each, and moved the checkpoint forward."
