#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=datavault-exports

pending="$(aws_local s3api list-multipart-uploads --bucket "$B" --query 'length(Uploads || `[]`)' --output text)"
if [ "$pending" != "0" ]; then
  echo "$pending incomplete multipart upload(s) are still stored in the bucket and still billed."
  exit 1
fi

cfg="$(aws_local s3api get-bucket-lifecycle-configuration --bucket "$B" --output json 2>/dev/null || echo '{}')"
printf '%s' "$cfg" | python3 -c '
import json, sys
rules = json.load(sys.stdin).get("Rules", [])
def prefix(r):
    f = r.get("Filter")
    if f is None:
        return r.get("Prefix", "")
    return f.get("Prefix", f.get("And", {}).get("Prefix", ""))

# The old transition rule must survive.
kept = [r for r in rules if r.get("Status") == "Enabled" and any(
        t.get("StorageClass") == "STANDARD_IA" and t.get("Days") == 30 for t in r.get("Transitions", []))]
if not kept:
    print("The existing rule that moves exports/ to STANDARD_IA after 30 days is gone. put-bucket-lifecycle-configuration replaces the whole configuration, so send the old rule again with the new one.")
    sys.exit(1)

aborts = [r for r in rules if r.get("Status") == "Enabled" and "AbortIncompleteMultipartUpload" in r]
if not aborts:
    print("No enabled rule aborts incomplete multipart uploads yet.")
    sys.exit(1)
# Must cover the whole bucket (the stray upload under tmp/ proves exports/ alone is not enough).
whole = [r for r in aborts if prefix(r) == "" and "Tag" not in r.get("Filter", {}) and "And" not in r.get("Filter", {})]
if not whole:
    print("An abort rule exists but it only covers part of the bucket. Abandoned uploads also appear under other prefixes (tmp/).")
    sys.exit(1)
if min(r["AbortIncompleteMultipartUpload"]["DaysAfterInitiation"] for r in whole) > 7:
    print("The abort rule waits more than 7 days.")
    sys.exit(1)
print("Incomplete uploads are cleaned up now, will be aborted after at most 7 days everywhere, and the transition rule is intact.")
'
