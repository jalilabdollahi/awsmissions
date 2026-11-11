#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=hotline-media

head_field() { aws_local s3api head-object --bucket "$B" --key "$1" --query "$2" --output text; }

for key in live/autumn-banner.png live/site.css; do
  sc="$(head_field "$key" StorageClass)"
  if [ "$sc" != "STANDARD" ] && [ "$sc" != "None" ]; then
    echo "$key is still stored as $sc."
    exit 1
  fi
done

if [ "$(head_field live/autumn-banner.png ContentType)" != "image/png" ]; then
  echo "live/autumn-banner.png lost its Content-Type (now $(head_field live/autumn-banner.png ContentType)). Re-storing an object must keep its metadata."
  exit 1
fi
if [ "$(head_field live/site.css ContentType)" != "text/css" ]; then
  echo "live/site.css lost its Content-Type."
  exit 1
fi
if [ "$(head_field live/autumn-banner.png Metadata.campaign)" != "autumn" ] || [ "$(head_field live/site.css Metadata.owner)" != "web" ]; then
  echo "A live object lost its user metadata (campaign / owner)."
  exit 1
fi
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
aws_local s3api get-object --bucket "$B" --key live/site.css "$work/css" >/dev/null
if ! grep -q 'color: #222' "$work/css"; then
  echo "live/site.css content changed."
  exit 1
fi

if [ "$(head_field archive/2019-promo.png StorageClass)" != "GLACIER" ]; then
  echo "archive/2019-promo.png was moved out of GLACIER. Old campaigns belong in the archive class."
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
archiving = ("GLACIER", "DEEP_ARCHIVE", "GLACIER_IR")
for r in rules:
    if r.get("Status") != "Enabled":
        continue
    if any(t.get("StorageClass") in archiving for t in r.get("Transitions", [])) and "live/x".startswith(prefix(r)):
        print("Rule %s still transitions objects under live/ to an archive class." % r["ID"]); sys.exit(1)
ok = [r for r in rules if r.get("Status") == "Enabled" and prefix(r) == "archive/"
      and any(t.get("StorageClass") == "GLACIER" and t.get("Days") == 90 for t in r.get("Transitions", []))]
if not ok:
    print("The rule that archives archive/ after 90 days is missing. Only the live/ problem had to be fixed."); sys.exit(1)
'
echo "live/ is back in STANDARD with its metadata, the archive rule is intact, and nothing will re-archive live files."
