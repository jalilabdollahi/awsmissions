#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://orbit-ledger-books >/dev/null
seed="$(mktemp)"
trap 'rm -f "$seed"' EXIT
printf 'account,balance\n1000,52210.10\n' > "$seed"
aws_local s3api put-object --bucket orbit-ledger-books --key 2025/trial-balance.csv --body "$seed" >/dev/null

# Two principals that are both allowed to *call* AssumeRole; only one is trusted.
aws_local iam create-user --user-name ledger-batch >/dev/null
aws_local iam create-user --user-name temp-auditor >/dev/null
for u in ledger-batch temp-auditor; do
  aws_local iam put-user-policy --user-name "$u" --policy-name may-assume-roles \
    --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"sts:AssumeRole","Resource":"*"}]}'
done

aws_local iam create-role --role-name ledger-nightly \
  --assume-role-policy-document "file://$MISSION_DIR/workspace/trust-policy.json" >/dev/null
aws_local iam put-role-policy --role-name ledger-nightly --policy-name read-books \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::orbit-ledger-books/*"}]}'

echo "ledger-nightly exists, ledger-batch may call AssumeRole, but the assume still fails."
