#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# "prd" in the ARN should have been "prod".
python3 - <<'PY'
import json
doc = json.load(open("policy.json"))
for st in doc["Statement"]:
    st["Resource"] = st["Resource"].replace("quokka/prd/", "quokka/prod/")
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-role-policy --role-name quokka-api --policy-name quokka-secrets \
  --policy-document file://policy.json
