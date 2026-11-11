#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# The value was "45s"; a Number parameter wants 45.
python3 - <<'PY'
import json
params = json.load(open("params.json"))
for p in params:
    if p["ParameterKey"] == "TimeoutSeconds":
        p["ParameterValue"] = "45"
json.dump(params, open("params.json", "w"), indent=2)
PY

# A ROLLBACK_COMPLETE stack can only be deleted, not updated.
aws_local cloudformation delete-stack --stack-name quarry-resizer
aws_local cloudformation wait stack-delete-complete --stack-name quarry-resizer
aws_local cloudformation create-stack --stack-name quarry-resizer \
  --template-body file://template.yaml --parameters file://params.json >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name quarry-resizer
