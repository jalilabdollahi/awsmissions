#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
aws_local s3api put-bucket-request-payment --bucket mission-bucket --request-payment-configuration Payer=Requester >/dev/null
echo "Broken bucket created: mission-bucket (requester pays enabled)"
