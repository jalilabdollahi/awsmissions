#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("lifecycle.json"))
for rule in doc["Rules"]:
    if rule["ID"] == "expire-debug-logs":
        rule["Filter"]["Prefix"] = "app-logs/debug/"
json.dump(doc, open("lifecycle.json", "w"), indent=2)
PY

aws_local s3api put-bucket-lifecycle-configuration --bucket ember-app-logs \
  --lifecycle-configuration file://lifecycle.json
