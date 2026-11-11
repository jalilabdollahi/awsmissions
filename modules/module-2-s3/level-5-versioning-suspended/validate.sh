#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=pixelcart-feature-flags
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

status="$(aws_local s3api get-bucket-versioning --bucket "$B" --query Status --output text 2>/dev/null || true)"
if [ "$status" != "Enabled" ]; then
  echo "Versioning on $B is '${status:-never set}'. New uploads will not get their own versions."
  exit 1
fi

# The live object must be the last good document again.
if ! aws_as_user flag-publisher s3api get-object --bucket "$B" --key flags.json "$work/live.json" >/dev/null 2>&1; then
  echo "flag-publisher cannot read flags.json."
  exit 1
fi
if ! python3 - "$work/live.json" <<'PY'
import json, sys
try:
    doc = json.load(open(sys.argv[1]))
except ValueError:
    sys.exit(1)
sys.exit(0 if doc.get("new_checkout") is True and doc.get("rollout") == 50 else 1)
PY
then
  echo "flags.json served by the bucket is still not the last good document (new_checkout true, rollout 50)."
  exit 1
fi

# The history must not have been thrown away.
real_versions="$(aws_local s3api list-object-versions --bucket "$B" --prefix flags.json \
  --query 'length(Versions[?VersionId!=`null`])' --output text)"
if [ "$real_versions" -lt 2 ]; then
  echo "The earlier published versions of flags.json are gone. Restore the good one without deleting history."
  exit 1
fi

# Future uploads: two writes must give two distinct, real version ids.
echo '{"probe": 1}' > "$work/p1.json"
echo '{"probe": 2}' > "$work/p2.json"
v1="$(aws_as_user flag-publisher s3api put-object --bucket "$B" --key probe/flags-check.json --body "$work/p1.json" --query VersionId --output text 2>/dev/null || true)"
v2="$(aws_as_user flag-publisher s3api put-object --bucket "$B" --key probe/flags-check.json --body "$work/p2.json" --query VersionId --output text 2>/dev/null || true)"
if [ -z "$v1" ] || [ "$v1" = "None" ] || [ "$v1" = "null" ] || [ "$v1" = "$v2" ]; then
  echo "Two uploads did not produce two distinct version ids (got '$v1' and '$v2')."
  exit 1
fi

echo "Versioning is on again, flags.json is the last good document, and every new upload gets its own version."
