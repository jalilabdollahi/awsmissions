#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/vl-reader-role"
bad=0
echo "Patient-notes key audit (INC-7702)"

KEY="$(aws_local kms describe-key --key-id alias/vl-patient-notes --query KeyMetadata.KeyId --output text 2>/dev/null || true)"
if [ -z "$KEY" ] || [ "$KEY" = "None" ]; then
  echo "alias/vl-patient-notes no longer exists. The notes were encrypted under that key; do not re-key."
  exit 1
fi

# Guardrail: the reader must not be able to use the billing key.
bill_ct="$(aws_local dynamodb get-item --table-name vl-vault --key '{"noteId":{"S":"bill-1"}}' --query Item.ct.S --output text)"
bf="$(mktemp)"; printf '%s' "$bill_ct" | base64 -d > "$bf" 2>/dev/null || true
rc=0
aws_as_role "$ROLE_ARN" vl-oncall "" kms decrypt --ciphertext-blob "fileb://$bf" >/dev/null 2>&1 || rc=$?
rm -f "$bf"
if [ "$rc" -eq 98 ]; then echo "vl-oncall cannot assume vl-reader-role any more; leave the trust policy."; exit 1; fi
if [ "$rc" -eq 0 ]; then
  echo "BLOCKER: the reader role can decrypt the finance team's billing data. Scope the permission to the patient-notes key."
  exit 1
fi

# 1. Key state.
state="$(aws_local kms describe-key --key-id "$KEY" --query KeyMetadata.KeyState --output text)"
if [ "$state" = "Enabled" ]; then
  echo "[ok]    key      the patient-notes key is Enabled"
else
  echo "[FAULT] key      the patient-notes key is in state $state"
  bad=$((bad + 1))
fi

# 2. Rotation.
rot="$(aws_local kms get-key-rotation-status --key-id "$KEY" --query KeyRotationEnabled --output text 2>/dev/null || echo False)"
if [ "$rot" = "True" ] || [ "$rot" = "true" ]; then
  echo "[ok]    rotation automatic rotation is enabled"
else
  echo "[FAULT] rotation the patient-notes key does not rotate automatically (control 7.3)"
  bad=$((bad + 1))
fi

# 3. Alias used by the function.
alias_cfg="$(aws_local lambda get-function-configuration --function-name vl-note-reader --query 'Environment.Variables.KEY_ALIAS' --output text 2>/dev/null || echo None)"
if aws_local kms describe-key --key-id "$alias_cfg" >/dev/null 2>&1; then
  echo "[ok]    config   KEY_ALIAS ($alias_cfg) resolves to a key"
else
  echo "[FAULT] config   KEY_ALIAS ('$alias_cfg') does not resolve to any key"
  bad=$((bad + 1))
fi

# 4. IAM: ask KMS as the role (a disabled key reports a state error, a missing permission reports AccessDenied).
pt="$(printf 'probe' | base64)"
if [ "$state" = "Enabled" ]; then
  if out="$(aws_as_role "$ROLE_ARN" vl-oncall "" kms encrypt --key-id alias/vl-patient-notes --plaintext "$pt" --query CiphertextBlob --output text 2>&1)"; then
    echo "[ok]    iam      the role may encrypt with the patient-notes key"
    ctf="$(mktemp)"; printf '%s' "$out" | base64 -d > "$ctf"
    if aws_as_role "$ROLE_ARN" vl-oncall "" kms decrypt --ciphertext-blob "fileb://$ctf" >/dev/null 2>&1; then
      echo "[ok]    iam      the role may decrypt notes"
    else
      echo "[FAULT] iam      the role cannot decrypt notes"
      bad=$((bad + 1))
    fi
    rm -f "$ctf"
  else
    echo "[FAULT] iam      KMS refuses the role on the patient-notes key: $(printf '%s' "$out" | tail -1 | cut -c1-110)"
    bad=$((bad + 1))
  fi
else
  if aws_local iam get-role-policy --role-name vl-reader-role --policy-name reader --query PolicyDocument --output json | grep -q "$KEY"; then
    echo "[ok]    iam      the role's policy names the patient-notes key (not yet exercised)"
  else
    echo "[FAULT] iam      the role's KMS permission does not cover the patient-notes key"
    bad=$((bad + 1))
  fi
fi

if [ "$bad" -gt 0 ]; then
  echo "$bad item(s) still broken. Not opening the note yet."
  exit 1
fi
out="$(mktemp)"
aws_local lambda invoke --function-name vl-note-reader --cli-binary-format raw-in-base64-out --payload '{"noteId":"n-1"}' "$out" >"$out.meta" 2>&1 || true
if [ -n "$(jq -r '.FunctionError // empty' "$out.meta" 2>/dev/null)" ] || ! jq -e '.note | startswith("Patient reports")' "$out" >/dev/null 2>&1; then
  echo "Opening note n-1 failed: $(jq -r '.errorMessage // empty' "$out" | cut -c1-150)"
  rm -f "$out" "$out.meta"
  exit 1
fi
rm -f "$out" "$out.meta"
echo "Note n-1 opens, re-archives, and the key is safe and rotating. Clinicians are back."
