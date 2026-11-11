#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for t in orbit-shipments orbit-payroll; do
  key=shipmentId; [ "$t" = orbit-payroll ] && key=employeeId
  aws_local dynamodb create-table --table-name "$t" \
    --attribute-definitions "AttributeName=$key,AttributeType=S" \
    --key-schema "AttributeName=$key,KeyType=HASH" \
    --billing-mode PAY_PER_REQUEST >/dev/null
done
aws_local dynamodb put-item --table-name orbit-payroll \
  --item '{"employeeId":{"S":"e-1"},"salary":{"N":"91000"}}'

ship() {
  aws_local dynamodb put-item --table-name orbit-shipments --item \
    "{\"shipmentId\":{\"S\":\"$1\"},\"region\":{\"S\":\"$2\"},\"shippedAt\":{\"N\":\"$3\"},\"carrier\":{\"S\":\"$4\"}}"
}
ship s-1001 emea 1767000000 dhl
ship s-1002 emea 1767100000 ups
ship s-1003 emea 1767200000 dhl
ship s-1004 apac 1767150000 sf
ship s-1005 amer 1767250000 fedex

aws_local iam create-user --user-name orbit-report-svc >/dev/null
aws_local iam put-user-policy --user-name orbit-report-svc --policy-name report-reads \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"NightlyScan\",\"Effect\":\"Allow\",\"Action\":\"dynamodb:Scan\",\"Resource\":\"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/orbit-shipments\"}]}"

echo "orbit-report-svc scans orbit-shipments every night. Security wants that to stop."
