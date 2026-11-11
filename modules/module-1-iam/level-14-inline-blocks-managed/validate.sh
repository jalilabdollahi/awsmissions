#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

file="$(mktemp)"
trap 'rm -f "$file"' EXIT
echo "build $(date +%s)" > "$file"
deployer() { aws_as_user forge-deployer "$@"; }

if ! aws_local iam list-attached-user-policies --user-name forge-deployer \
     --query 'AttachedPolicies[].PolicyName' --output text | tr '\t' '\n' | grep -qx AmazonS3FullAccess; then
  echo "AmazonS3FullAccess was detached from forge-deployer. The Allow was never the problem; put it back."
  exit 1
fi

if ! out="$(deployer s3api put-object --bucket forge-artifacts --key builds/0142.tar --body "$file" 2>&1)"; then
  echo "Uploading to forge-artifacts as forge-deployer still fails: $(printf '%s' "$out" | tail -1)"
  echo "The user already has an Allow from the managed policy. Something else on the user must be overriding it: list its inline policies."
  exit 1
fi
if ! deployer s3api delete-object --bucket forge-artifacts --key builds/0141.tar >/dev/null 2>&1; then
  echo "Uploads work, but deleting old builds from forge-artifacts is still blocked."
  exit 1
fi

# The ledger protection was intentional and must survive.
if deployer s3api put-object --bucket forge-ledger-prod --key books/tamper.csv --body "$file" >/dev/null 2>&1; then
  echo "forge-deployer can now write to forge-ledger-prod. That bucket was protected on purpose; only remove the Deny that is stale."
  exit 1
fi
if deployer s3api delete-object --bucket forge-ledger-prod --key books/2025.csv >/dev/null 2>&1; then
  echo "forge-deployer can delete from forge-ledger-prod. Keep the ledger guardrail."
  exit 1
fi
if ! deployer s3api get-object --bucket forge-ledger-prod --key books/2025.csv "$file" >/dev/null 2>&1; then
  echo "Reading the ledger no longer works either; you removed more than the stale statement."
  exit 1
fi

echo "forge-deployer ships to forge-artifacts again, and the ledger is still write-protected."
