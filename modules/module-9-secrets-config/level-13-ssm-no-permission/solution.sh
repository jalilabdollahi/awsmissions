#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

kiln_key="$(aws_local kms describe-key --key-id alias/kiln-config --query KeyMetadata.Arn --output text)"

KEY_ARN="$kiln_key" python3 - <<'PY'
import json, os
doc = json.load(open("policy.json"))
stmt = doc["Statement"][0]
stmt["Action"] = ["ssm:GetParameter", "ssm:GetParameters"]
stmt["Resource"] = "arn:aws:ssm:us-east-1:000000000000:parameter/kiln/prod/*"
doc["Statement"].append({
    "Sid": "DecryptKilnConfig",
    "Effect": "Allow",
    "Action": "kms:Decrypt",
    "Resource": os.environ["KEY_ARN"],
})
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-role-policy --role-name kiln-task --policy-name kiln-task-config \
  --policy-document file://policy.json
