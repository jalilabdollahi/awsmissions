#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("notification.json"))
for rule in doc["QueueConfigurations"]:
    if rule["Id"] == "thumbnail-on-upload":
        rule["Events"] = ["s3:ObjectCreated:*"]
json.dump(doc, open("notification.json", "w"), indent=2)
PY

aws_local s3api put-bucket-notification-configuration --bucket snapfolio-gallery \
  --notification-configuration file://notification.json
