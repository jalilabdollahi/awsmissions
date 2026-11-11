#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("trust.json"))
for stmt in doc["Statement"]:
    if stmt["Principal"].get("Service") == "ec2.amazonaws.com":
        stmt["Sid"] = "FromLambda"
        stmt["Principal"]["Service"] = "lambda.amazonaws.com"
json.dump(doc, open("trust.json", "w"), indent=2)
PY

aws_local iam update-assume-role-policy --role-name lumen-thumb-scanner \
  --policy-document file://trust.json
