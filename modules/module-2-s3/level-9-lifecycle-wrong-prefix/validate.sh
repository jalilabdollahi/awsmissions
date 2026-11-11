#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=ember-app-logs
rules="$(aws_local s3api get-bucket-lifecycle-configuration --bucket "$B" --output json 2>/dev/null || echo '{}')"
keys="$(aws_local s3api list-objects-v2 --bucket "$B" --query 'Contents[].Key' --output json)"

# For every stored key, work out the shortest expiration among the enabled rules that apply.
python3 - "$rules" "$keys" <<'PY'
import json, sys

rules = json.loads(sys.argv[1]).get("Rules", [])
keys = json.loads(sys.argv[2]) or []

def prefix_of(rule):
    f = rule.get("Filter")
    if f is None:
        return rule.get("Prefix", "")
    if "Prefix" in f:
        return f["Prefix"]
    if "And" in f:
        return f["And"].get("Prefix", "")
    return ""   # tag/size-only filters apply to every key as far as this check goes

def expiry(key):
    days = [r["Expiration"]["Days"] for r in rules
            if r.get("Status") == "Enabled" and "Days" in r.get("Expiration", {})
            and key.startswith(prefix_of(r))]
    return min(days) if days else None

def fail(msg):
    print(msg)
    sys.exit(1)

for key in keys:
    d = expiry(key)
    if key.startswith("app-logs/audit/"):
        if d is not None:
            fail("The audit log %s is covered by an expiration rule (%d days). Audit logs must never expire." % (key, d))
    elif key.startswith("app-logs/debug/"):
        if d is None:
            fail("Nothing expires %s. Compare each rule's prefix with the real object keys (aws s3 ls --recursive)." % key)
        if d > 14:
            fail("%s would only expire after %d days; debug logs must go after 14 at most." % (key, d))
    elif key.startswith("app-logs/error/"):
        if d is None or d > 90:
            fail("Error logs must expire after at most 90 days, but %s is covered by: %s." % (key, d))
print("Debug logs expire in 14 days, error logs in 90, and the audit logs are exempt.")
PY
