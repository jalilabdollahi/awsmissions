#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
json.dump({"IndexDocument": {"Suffix": "index.html"}, "ErrorDocument": {"Key": "404.html"}},
          open("website.json", "w"), indent=2)
PY

aws_local s3api put-bucket-website --bucket driftwood-docs-site --website-configuration file://website.json
