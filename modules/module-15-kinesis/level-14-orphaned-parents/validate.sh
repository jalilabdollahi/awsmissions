#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# A fresh write for every account: it goes to whichever shard is open now.
stamp="$(date +%s)"
for acct in 1 2 3 4; do
  aws_local kinesis put-record --stream-name ledger-entries --partition-key "acct-$acct" \
    --data "$(printf '{"account":"acct-%s","seq":%s,"cents":1}' "$acct" "$stamp" | base64)" >/dev/null
done

out="$(mktemp)"
trap 'rm -f "$out" "$out.meta"' EXIT
aws_local lambda invoke --function-name ledger-export --cli-binary-format raw-in-base64-out \
  --payload '{}' "$out" > "$out.meta" 2>&1 || true
if grep -q FunctionError "$out.meta"; then
  echo "ledger-export crashed: $(jq -r '.errorMessage // "unknown error"' "$out")"
  exit 1
fi

# Every seeded entry (accounts 1-4, seq 1-6) and today's probes must be present, each exactly once.
missing=""
for acct in 1 2 3 4; do
  for seq in 1 2 3 4 5 6 "$stamp"; do
    n="$(jq --arg a "acct-$acct" --argjson s "$seq" '[.entries[] | select(.account == $a and .seq == $s)] | length' "$out")"
    if [ "$n" = "0" ]; then missing="$missing acct-$acct/seq$seq"; fi
    if [ "$n" -gt 1 ]; then
      echo "Entry acct-$acct seq $seq appears $n times in the export. Each entry must appear exactly once."
      exit 1
    fi
  done
done
if [ -n "$missing" ]; then
  total="$(jq '.entries | length' "$out")"
  echo "The export returned $total entries and is missing, among others:$(printf '%s' "$missing" | cut -c1-120)"
  exit 1
fi

bad="$(jq -r '[.entries | group_by(.account)[] | . as $g | [range(1; ($g|length))] | map(select($g[.].seq <= $g[. - 1].seq))] | flatten | length' "$out")"
if [ "$bad" != "0" ]; then
  echo "Within at least one account the entries are not in write order (seq must increase). When a shard was split, its parent has to be read completely before its children."
  exit 1
fi

echo "ledger-export returned all entries exactly once, in per-account write order, including the one written just now."
