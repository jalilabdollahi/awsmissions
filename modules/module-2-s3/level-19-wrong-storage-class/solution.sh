#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=hotline-media

# Copy each live object onto itself in STANDARD. The default directive (COPY) keeps metadata.
for key in live/autumn-banner.png live/site.css; do
  aws_local s3api copy-object --bucket "$B" --key "$key" --copy-source "$B/$key" \
    --storage-class STANDARD --metadata-directive COPY >/dev/null
done

# Drop the rule that targets live/, keep the archive rule.
python3 - <<'PY'
import json
doc = json.load(open("lifecycle.json"))
doc["Rules"] = [r for r in doc["Rules"] if r["ID"] != "age-out-media"]
json.dump(doc, open("lifecycle.json", "w"), indent=2)
PY
aws_local s3api put-bucket-lifecycle-configuration --bucket "$B" --lifecycle-configuration file://lifecycle.json
