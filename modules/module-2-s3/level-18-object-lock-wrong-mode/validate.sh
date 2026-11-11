#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=fennel-ledger-archive
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# 1. Every stored version under ledger/ must be in COMPLIANCE mode until at least 2028-01-01.
vids="$(aws_local s3api list-object-versions --bucket "$B" --prefix ledger/ \
  --query 'Versions[].[Key,VersionId]' --output text)"
checked=0
while read -r key vid; do
  [ -n "${key:-}" ] || continue
  checked=$((checked + 1))
  ret="$(aws_local s3api get-object-retention --bucket "$B" --key "$key" --version-id "$vid" \
    --query 'Retention.[Mode,RetainUntilDate]' --output text 2>/dev/null || echo "NONE NONE")"
  mode="$(printf '%s' "$ret" | awk '{print $1}')"
  until="$(printf '%s' "$ret" | awk '{print $2}')"
  if [ "$mode" != "COMPLIANCE" ]; then
    echo "$key (version $vid) is in $mode mode. Every ledger version must be COMPLIANCE."
    exit 1
  fi
  if [ "$(printf '%s' "$until" | cut -c1-10)" \< "2028-01-01" ]; then
    echo "$key (version $vid) is retained only until $until, less than the original 2028-01-01."
    exit 1
  fi
done <<EOT
$vids
EOT
if [ "$checked" -lt 3 ]; then
  echo "Only $checked ledger version(s) found; expected 3. Versions must not be deleted."
  exit 1
fi

# 2. The bucket default for new objects.
cfg="$(aws_local s3api get-object-lock-configuration --bucket "$B" --output json)"
printf '%s' "$cfg" | python3 -c '
import json, sys
c = json.load(sys.stdin)["ObjectLockConfiguration"]
if c.get("ObjectLockEnabled") != "Enabled":
    print("Object Lock is no longer enabled on the bucket."); sys.exit(1)
d = c.get("Rule", {}).get("DefaultRetention", {})
if d.get("Mode") != "COMPLIANCE":
    print("The bucket default retention mode is %s. New objects must default to COMPLIANCE." % d.get("Mode")); sys.exit(1)
days = d.get("Days", 0) + 365 * d.get("Years", 0)
if days < 2555:
    print("The default retention is only about %d days; 7 years (2555 days) are required." % days); sys.exit(1)
'

# 3. Behaviour: a brand-new object picks up the default and cannot be unlocked, even by root.
echo "probe $(date +%s)" > "$work/probe"
vid="$(aws_local s3api put-object --bucket "$B" --key "ledger/probe-$(date +%s).csv" --body "$work/probe" \
  --query VersionId --output text)"
key="$(aws_local s3api list-object-versions --bucket "$B" --prefix ledger/probe- --query 'Versions[0].Key' --output text)"
pmode="$(aws_local s3api head-object --bucket "$B" --key "$key" --version-id "$vid" --query ObjectLockMode --output text)"
if [ "$pmode" != "COMPLIANCE" ]; then
  echo "A freshly uploaded object is locked in '$pmode' mode, not COMPLIANCE."
  exit 1
fi
if aws_local s3api delete-object --bucket "$B" --key "$key" --version-id "$vid" --bypass-governance-retention >/dev/null 2>&1; then
  echo "A new object could be deleted with --bypass-governance-retention; it is not truly immutable."
  exit 1
fi
echo "All ledger versions are COMPLIANCE-locked and new objects default to COMPLIANCE for 7+ years."
