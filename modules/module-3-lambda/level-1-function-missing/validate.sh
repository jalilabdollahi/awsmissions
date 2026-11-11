#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

FN=parcel-label-formatter
out="$(mktemp)"
trap 'rm -f "$out" "$out.meta"' EXIT

if ! cfg="$(aws_local lambda get-function-configuration --function-name "$FN" 2>&1)"; then
  echo "The dispatch job still cannot find $FN: $(printf '%s' "$cfg" | tail -1)"
  exit 1
fi

role="$(printf '%s' "$cfg" | jq -r '.Role')"
if [ "$role" != "arn:aws:iam::${ACCOUNT_ID}:role/parcel-label-role" ]; then
  echo "$FN exists but runs as $role. Platform policy: it must use the existing parcel-label-role."
  exit 1
fi

# Behaviour: call it exactly like the dispatch job does.
call() {
  aws_local lambda invoke --function-name "$FN" --cli-binary-format raw-in-base64-out \
    --payload "$1" "$out" >"$out.meta" 2>&1 || { echo "Invoke failed: $(tail -1 "$out.meta")"; return 1; }
  if jq -e '.FunctionError // empty' "$out.meta" >/dev/null 2>&1; then
    echo "$FN was found but crashed on invocation: $(head -c 300 "$out")"
    return 1
  fi
}

call '{"city":" tacoma ","state":"wa","zip":"98402","weight_kg":2.5,"service":"air"}' || exit 1
got="$(jq -r '.label // empty' "$out")"
if [ "$got" != "TACOMA, WA 98402 | AR | 2.5KG" ]; then
  echo "The label came back wrong: '$got'. Is the deployed code the one from the workspace?"
  exit 1
fi

call '{"city":"Reno","state":"NV","zip":"89501","weight_kg":31,"service":"ground"}' || exit 1
if [ "$(jq -r '.needs_signature' "$out")" != "true" ]; then
  echo "Heavy parcels must be flagged needs_signature. The deployed code does not look like the workspace version."
  exit 1
fi

echo "parcel-label-formatter is back: labels are printing again."
