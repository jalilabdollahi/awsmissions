#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SRC=corvid-storefront-assets
LOGS=corvid-access-logs

cfg="$(aws_local s3api get-bucket-logging --bucket "$SRC" --output json 2>/dev/null || true)"
[ -n "$cfg" ] || cfg='{}'
target="$(printf '%s' "$cfg" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("LoggingEnabled",{}).get("TargetBucket",""))')"
prefix="$(printf '%s' "$cfg" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("LoggingEnabled",{}).get("TargetPrefix",""))')"

if [ -z "$target" ]; then
  echo "Server access logging is not enabled on $SRC."
  exit 1
fi
if [ "$target" = "$SRC" ]; then
  echo "Logs are delivered into the bucket they describe. Every log write would create another log record; use a dedicated log bucket."
  exit 1
fi
if [ "$target" != "$LOGS" ]; then
  echo "Logs go to '$target', but security asked for the dedicated bucket $LOGS."
  exit 1
fi
if [ "$prefix" != "storefront/" ]; then
  echo "The log prefix is '$prefix'. Logs must be delivered under storefront/."
  exit 1
fi
if ! aws_local s3api head-bucket --bucket "$LOGS" >/dev/null 2>&1; then
  echo "The log bucket $LOGS does not exist, so delivery would fail silently."
  exit 1
fi

pol="$(aws_local s3api get-bucket-policy --bucket "$LOGS" --query Policy --output text 2>/dev/null || true)"
if [ -z "$pol" ] || [ "$pol" = "None" ]; then
  echo "$LOGS has no bucket policy, so the S3 logging service cannot write into it."
  exit 1
fi
printf '%s' "$pol" | python3 -c '
import json, sys
doc = json.load(sys.stdin)
stmts = doc["Statement"]
if isinstance(stmts, dict):
    stmts = [stmts]
def as_list(x):
    return x if isinstance(x, list) else [x]
good = False
for s in stmts:
    if s.get("Effect") != "Allow":
        continue
    princ = s.get("Principal")
    if princ == "*" or (isinstance(princ, dict) and "*" in as_list(princ.get("AWS", []))):
        print("The log bucket policy grants access to everyone. Only the logging service principal may write there.")
        sys.exit(1)
    if not (isinstance(princ, dict) and "logging.s3.amazonaws.com" in as_list(princ.get("Service", []))):
        continue
    actions = as_list(s.get("Action", []))
    if not any(a in ("s3:PutObject", "s3:*") for a in actions):
        continue
    for res in as_list(s.get("Resource", [])):
        # The grant must cover keys under storefront/ in this bucket.
        if res in ("arn:aws:s3:::corvid-access-logs/*", "arn:aws:s3:::corvid-access-logs/storefront/*"):
            good = True
if not good:
    print("The log bucket policy does not allow logging.s3.amazonaws.com to s3:PutObject on the storefront/ log keys.")
    sys.exit(1)
print("Access logging is on, delivered to corvid-access-logs under storefront/, and only the logging service may write there.")
'
