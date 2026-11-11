#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<PY
import json
doc = json.load(open("policy.json"))
doc["Statement"].append({
    "Sid": "HandOverPromoRole",
    "Effect": "Allow",
    "Action": "iam:PassRole",
    "Resource": "arn:aws:iam::${ACCOUNT_ID}:role/promo-fn-role",
    "Condition": {"StringEquals": {"iam:PassedToService": "lambda.amazonaws.com"}},
})
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-user-policy --user-name kestrel-releaser --policy-name release-pipeline \
  --policy-document file://policy.json
