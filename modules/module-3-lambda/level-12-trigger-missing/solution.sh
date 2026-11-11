#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("notification.json"))
cfg = doc["LambdaFunctionConfigurations"][0]
cfg["LambdaFunctionArn"] = "arn:aws:lambda:us-east-1:000000000000:function:lab-result-indexer"
cfg["Events"] = ["s3:ObjectCreated:*"]
rules = cfg["Filter"]["Key"]["FilterRules"]
rules[0]["Value"] = "results/"
rules[1]["Value"] = ".json"
json.dump(doc, open("notification.json", "w"), indent=2)
PY

aws_local s3api put-bucket-notification-configuration --bucket helixia-lab-inbox \
  --notification-configuration file://notification.json
