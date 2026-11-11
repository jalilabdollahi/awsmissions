#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

FN=claim-receipt-archiver
res="$(mktemp)"; hdr="$(mktemp)"
trap 'rm -f "$res" "$hdr"' EXIT

role_arn="$(aws_local lambda get-function-configuration --function-name "$FN" --query Role --output text 2>/dev/null)" || {
  echo "$FN has been deleted. Keep the function and fix its role."; exit 1; }
role_name="${role_arn##*/}"

if ! trust="$(aws_local iam get-role --role-name "$role_name" --query 'Role.AssumeRolePolicyDocument' --output json 2>/dev/null)"; then
  echo "The function's execution role ($role_arn) still does not exist in IAM."
  exit 1
fi
if ! printf '%s' "$trust" | jq -e '[.Statement[] | select(.Effect=="Allow") | .Principal.Service] | flatten | index("lambda.amazonaws.com")' >/dev/null 2>&1; then
  echo "Role $role_name exists, but its trust policy does not let lambda.amazonaws.com assume it, so Lambda could never use it."
  exit 1
fi

invoke() {
  aws_local lambda invoke --function-name "$FN" --cli-binary-format raw-in-base64-out \
    --payload "$1" "$res" >"$hdr" 2>&1 || { echo "Invoke call failed: $(tail -1 "$hdr")"; return 1; }
}

claim="CLM-$(date +%s)"
invoke "{\"claim_id\":\"$claim\",\"text\":\"water damage, kitchen\"}" || exit 1
if jq -e '.FunctionError' "$hdr" >/dev/null 2>&1; then
  echo "Archiving a receipt fails: $(jq -r '.errorMessage' "$res" | head -c 250)"
  echo "The role needs to allow exactly what the function does."
  exit 1
fi
if ! aws_local s3api head-object --bucket tidewater-claim-receipts --key "receipts/$claim.txt" >/dev/null 2>&1; then
  echo "The function reported success but receipts/$claim.txt is not in tidewater-claim-receipts."
  exit 1
fi

# Least privilege: the override must not let it reach the legal-hold bucket.
invoke "{\"claim_id\":\"$claim\",\"text\":\"x\",\"bucket\":\"tidewater-claim-evidence\"}" || exit 1
if ! jq -e '.FunctionError' "$hdr" >/dev/null 2>&1; then
  echo "The role is too generous: the archiver could write into tidewater-claim-evidence (legal hold). Scope the permission to the receipts bucket only."
  exit 1
fi

echo "claim-receipt-archiver runs under $role_name: receipts are archived and the evidence bucket stays untouchable."
