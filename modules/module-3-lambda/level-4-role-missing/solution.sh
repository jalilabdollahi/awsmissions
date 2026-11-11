#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
trust = json.load(open("trust-policy.json"))
trust["Statement"][0]["Principal"]["Service"] = "lambda.amazonaws.com"
json.dump(trust, open("trust-policy.json", "w"), indent=2)

perms = json.load(open("permissions.json"))
perms["Statement"][0]["Action"] = "s3:PutObject"
perms["Statement"][0]["Resource"] = "arn:aws:s3:::tidewater-claim-receipts/receipts/*"
json.dump(perms, open("permissions.json", "w"), indent=2)
PY

aws_local iam create-role --role-name claim-archiver-role \
  --assume-role-policy-document file://trust-policy.json >/dev/null
aws_local iam put-role-policy --role-name claim-archiver-role --policy-name archive-receipts \
  --policy-document file://permissions.json
aws_local lambda update-function-configuration --function-name claim-receipt-archiver \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/claim-archiver-role" >/dev/null
