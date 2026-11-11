#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
rule = {
    "AllowedOrigins": ["https://dashboard.tidewater.example"],
    "AllowedMethods": ["GET", "PUT"],
    "AllowedHeaders": ["content-type"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000,
}
json.dump({"CORSRules": [rule]}, open("cors.json", "w"), indent=2)
PY

aws_local s3api put-bucket-cors --bucket tidewater-pod-photos --cors-configuration file://cors.json
