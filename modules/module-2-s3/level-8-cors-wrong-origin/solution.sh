#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("cors.json"))
for rule in doc["CORSRules"]:
    if rule["ID"] == "admin-editor":
        rule["AllowedOrigins"] = ["https://admin.brightcart.example"]
        rule["AllowedMethods"] = ["GET", "PUT", "DELETE"]
json.dump(doc, open("cors.json", "w"), indent=2)
PY

aws_local s3api put-bucket-cors --bucket brightcart-media --cors-configuration file://cors.json
