#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = {
    "Version": "2012-10-17",
    "Statement": [
        {"Sid": "ReadInvoices", "Effect": "Allow",
         "Action": ["s3:ListBucket"], "Resource": "arn:aws:s3:::bluefin-invoices"},
        {"Sid": "ReadInvoiceFiles", "Effect": "Allow",
         "Action": "s3:GetObject", "Resource": "arn:aws:s3:::bluefin-invoices/*"},
        {"Sid": "WriteDigests", "Effect": "Allow",
         "Action": "s3:PutObject", "Resource": "arn:aws:s3:::bluefin-digests/*"},
    ],
}
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-role-policy --role-name invoice-digest-role --policy-name digest-s3-access \
  --policy-document file://policy.json
