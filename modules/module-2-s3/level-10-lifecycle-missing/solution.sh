#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=datavault-exports

# Clean up what is stranded right now.
aws_local s3api list-multipart-uploads --bucket "$B" \
  --query 'Uploads[].[Key,UploadId]' --output text | while read -r key uid; do
  [ -n "${key:-}" ] && aws_local s3api abort-multipart-upload --bucket "$B" --key "$key" --upload-id "$uid"
done

# Add the abort rule next to the existing rule (the PUT replaces everything).
python3 - <<'PY'
import json
doc = json.load(open("lifecycle.json"))
doc["Rules"].append({
    "ID": "abort-stale-multipart",
    "Status": "Enabled",
    "Filter": {"Prefix": ""},
    "AbortIncompleteMultipartUpload": {"DaysAfterInitiation": 7},
})
json.dump(doc, open("lifecycle.json", "w"), indent=2)
PY
aws_local s3api put-bucket-lifecycle-configuration --bucket "$B" --lifecycle-configuration file://lifecycle.json
