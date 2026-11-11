#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

A="arn:aws:iam::${ACCOUNT_ID}"

# 1. The auditor may assume the bridge role (spelled correctly).
aws_local iam put-user-policy --user-name ashgrove-auditor --policy-name assume-bridge --policy-document \
  "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"$A:role/ferro-audit-bridge\"}]}"

# 2. Bridge trust policy: this year's ExternalId.
aws_local iam update-assume-role-policy --role-name ferro-audit-bridge --policy-document "{
  \"Version\":\"2012-10-17\",\"Statement\":[{
   \"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"$A:user/ashgrove-auditor\"},\"Action\":\"sts:AssumeRole\",
   \"Condition\":{\"StringEquals\":{\"sts:ExternalId\":\"ferro-ext-2026\"}}}]}"

# 3. Reader trusts the bridge under its current name.
aws_local iam update-assume-role-policy --role-name ferro-ledger-reader --policy-document "{
  \"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"$A:role/ferro-audit-bridge\"},\"Action\":\"sts:AssumeRole\"}]}"

# 4. Reader permission on the real bucket.
aws_local iam put-role-policy --role-name ferro-ledger-reader --policy-name read-2026 --policy-document '{
  "Version":"2012-10-17","Statement":[
   {"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::ferro-ledger-archive/2026/*"}]}'
