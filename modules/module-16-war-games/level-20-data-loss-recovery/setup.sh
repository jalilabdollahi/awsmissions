#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
B=ml-case-documents

aws_local s3 mb "s3://$B" >/dev/null
aws_local s3api put-bucket-versioning --bucket "$B" --versioning-configuration Status=Enabled
put() { printf '%s\n' "$2" > "$tmp/obj"; aws_local s3 cp "$tmp/obj" "s3://$B/$1" >/dev/null; }
put contracts/acme-msa.txt "MSA between Marlow & Quayle and Acme: term 36 months, fee schedule A."
put contracts/brightwater-nda.txt "NDA with Brightwater: mutual, 5 years."
put pleadings/calder-v-dunmore.txt "Calder v Dunmore: statement of claim filed 2026-09-02."
# The bad sync overwrote the Acme MSA with garbage.
put contracts/acme-msa.txt "CORRUPTED"

aws_local dynamodb create-table --table-name ml-case-index --attribute-definitions AttributeName=caseId,AttributeType=S \
  --key-schema AttributeName=caseId,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null
aws_local dynamodb update-continuous-backups --table-name ml-case-index \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true >/dev/null
sleep 2
for row in C-101:Acme C-102:Brightwater C-103:Calder C-104:Dunmore; do
  aws_local dynamodb put-item --table-name ml-case-index \
    --item "{\"caseId\":{\"S\":\"${row%%:*}\"},\"client\":{\"S\":\"${row##*:}\"}}" >/dev/null
done
sleep 3
aws_local ssm put-parameter --name /marlow/incident/last-good-time --type String --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >/dev/null
sleep 3

# The intern, with the old "full access" grants.
aws_local iam create-user --user-name ml-intern >/dev/null
aws_local iam put-user-policy --user-name ml-intern --policy-name casework --policy-document '{
  "Version":"2012-10-17","Statement":[
   {"Effect":"Allow","Action":"s3:*","Resource":["arn:aws:s3:::ml-case-documents","arn:aws:s3:::ml-case-documents/*"]},
   {"Effect":"Allow","Action":"dynamodb:*","Resource":"arn:aws:dynamodb:us-east-1:000000000000:table/ml-case-index"}]}'

# The clean-up.
for k in contracts/acme-msa.txt contracts/brightwater-nda.txt pleadings/calder-v-dunmore.txt; do
  aws_local s3 rm "s3://$B/$k" >/dev/null
done
for c in C-101 C-102 C-103 C-104; do
  aws_local dynamodb delete-item --table-name ml-case-index --key "{\"caseId\":{\"S\":\"$c\"}}" >/dev/null
done
# The "storage optimisation".
aws_local s3api put-bucket-versioning --bucket "$B" --versioning-configuration Status=Suspended

echo "INC-6611 is open: documents and cases are gone."
