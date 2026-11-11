#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. Remove the world-readable statement; keep the analyst grant.
aws_local s3api get-bucket-policy --bucket ardent-customer-exports --query Policy --output text > bucket-policy.json
python3 - <<'PY'
import json
doc = json.load(open("bucket-policy.json"))
doc["Statement"] = [s for s in doc["Statement"] if s.get("Sid") != "QuickShareForPartner"]
json.dump(doc, open("bucket-policy.json", "w"), indent=2)
PY
aws_local s3api put-bucket-policy --bucket ardent-customer-exports --policy file://bucket-policy.json

# 2. Staff group: reports only.
aws_local iam put-group-policy --group-name ardent-staff --policy-name staff-reading --policy-document '{
  "Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::ardent-customer-exports/reports/*"}]}'

# 3. Each partner: only their own folder.
for p in nova zephyr; do
  aws_local iam put-user-policy --user-name "ardent-partner-$p" --policy-name partner-feed --policy-document "{
    \"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::ardent-customer-exports/partners/$p/*\"}]}"
done
