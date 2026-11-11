#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://acornpay-invoices >/dev/null
aws_local sqs create-queue --queue-name invoice-intake >/dev/null

# The scanner service only needs to upload under inbox/.
aws_local iam create-user --user-name scanner-svc >/dev/null
aws_local iam put-user-policy --user-name scanner-svc --policy-name inbox-upload \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {"Effect": "Allow", "Action": "s3:PutObject", "Resource": "arn:aws:s3:::acornpay-invoices/*"}
    ]
  }'

# Deliberately no notification configuration on the bucket.
echo "Invoices are landing in inbox/ but the queue invoice-intake stays empty."
