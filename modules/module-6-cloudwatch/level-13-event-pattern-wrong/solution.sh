#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("pattern.json"))
doc["source"] = ["quillshop.orders"]
doc["detail"]["tier"] = ["gold"]
json.dump(doc, open("pattern.json", "w"), indent=2)
PY
aws_local events put-rule --name quillshop-gold-orders --state ENABLED \
  --event-pattern file://pattern.json
