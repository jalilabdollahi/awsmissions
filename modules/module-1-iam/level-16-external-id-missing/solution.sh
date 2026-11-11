#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("trust-policy.json"))
doc["Statement"][0]["Condition"]["StringEquals"]["sts:ExternalId"] = "mw-5d1f-prod-8841"
json.dump(doc, open("trust-policy.json", "w"), indent=2)
PY

aws_local iam update-assume-role-policy --role-name metricwave-reader \
  --policy-document file://trust-policy.json
