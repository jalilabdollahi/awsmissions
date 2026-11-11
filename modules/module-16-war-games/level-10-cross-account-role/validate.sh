#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

A="arn:aws:iam::${ACCOUNT_ID}"
BRIDGE="$A:role/ferro-audit-bridge"
READER="$A:role/ferro-ledger-reader"
EXT="ferro-ext-2026"
bad=0
echo "Audit access path check"

# --- helper: one assume-role hop, returns "AKID SECRET TOKEN" on stdout ---
hop() { # akid secret token role-arn session [external-id]
  local extra=""
  [ -n "${6:-}" ] && extra="--external-id $6"
  # shellcheck disable=SC2086
  aws_with_creds "$1" "$2" "$3" sts assume-role --role-arn "$4" --role-session-name "$5" $extra \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text 2>/dev/null
}
as_auditor() { # runs: as_auditor <command using $AK $SK> via callback; here we just mint a key
  aws_local iam create-access-key --user-name ashgrove-auditor --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text
}

for r in ferro-audit-bridge ferro-ledger-reader ferro-breakglass-admin; do
  if ! aws_local iam get-role --role-name "$r" >/dev/null 2>&1; then
    echo "Role $r is missing. Repair it, do not delete it."
    exit 1
  fi
done

ukey="$(as_auditor)"; UAK="$(echo "$ukey" | awk '{print $1}')"; USK="$(echo "$ukey" | awk '{print $2}')"
cleanup() { aws_local iam delete-access-key --user-name ashgrove-auditor --access-key-id "$UAK" >/dev/null 2>&1 || true; }
trap cleanup EXIT

# Guardrails: break-glass unreachable, ExternalId really required.
if hop "$UAK" "$USK" "" "$A:role/ferro-breakglass-admin" awsm-guard >/dev/null; then
  echo "BLOCKER: ashgrove-auditor can assume ferro-breakglass-admin. Allow the bridge role only, not every role."
  exit 1
fi
if hop "$UAK" "$USK" "" "$BRIDGE" awsm-noext >/dev/null; then
  echo "BLOCKER: the bridge role can be assumed without an ExternalId. The CISO requires it on hop 1."
  exit 1
fi
if hop "$UAK" "$USK" "" "$BRIDGE" awsm-wrongext "not-the-agreed-id" >/dev/null; then
  echo "BLOCKER: the bridge role accepts any ExternalId value."
  exit 1
fi

# Hop 1: user -> bridge (with the agreed ExternalId).
S1="$(hop "$UAK" "$USK" "" "$BRIDGE" awsm-hop1 "$EXT" || true)"
if [ -n "$S1" ]; then
  echo "[ok]    hop 1  ashgrove-auditor assumed ferro-audit-bridge with the agreed ExternalId"
else
  echo "[FAULT] hop 1  ashgrove-auditor cannot assume ferro-audit-bridge with ExternalId $EXT"
  bad=$((bad + 1))
  # Triage which side is wrong, without saying how to fix it.
  allowed="$(for p in $(aws_local iam list-user-policies --user-name ashgrove-auditor --query PolicyNames --output text); do
      aws_local iam get-user-policy --user-name ashgrove-auditor --policy-name "$p" --query PolicyDocument.Statement --output json
    done | jq -rs '[.[][] | select(.Effect == "Allow") | .Resource] | flatten | map(select(. == "'"$BRIDGE"'")) | length')"
  trust_ext="$(aws_local iam get-role --role-name ferro-audit-bridge --query 'Role.AssumeRolePolicyDocument' --output json | jq -r '[.Statement[].Condition.StringEquals["sts:ExternalId"]?] | map(select(. != null)) | join(",")')"
  if [ "$allowed" = "0" ]; then echo "          - the auditor's own permissions do not point at the bridge role"; fi
  if [ "$trust_ext" != "$EXT" ]; then echo "          - the bridge role's trust policy does not accept the agreed ExternalId"; fi
fi

# Hop 2: bridge -> reader (needs a working hop 1 to test for real).
trust_reader="$(aws_local iam get-role --role-name ferro-ledger-reader --query 'Role.AssumeRolePolicyDocument.Statement[].Principal.AWS' --output text | tr '\t' '\n')"
if [ -n "$S1" ]; then
  S2="$(hop "$(echo "$S1" | awk '{print $1}')" "$(echo "$S1" | awk '{print $2}')" "$(echo "$S1" | awk '{print $3}')" "$READER" awsm-hop2 || true)"
  if [ -n "$S2" ]; then
    echo "[ok]    hop 2  the bridge role chained into ferro-ledger-reader"
  else
    echo "[FAULT] hop 2  the bridge role cannot assume ferro-ledger-reader"
    bad=$((bad + 1))
  fi
else
  S2=""
  if printf '%s\n' "$trust_reader" | grep -qx "$BRIDGE"; then
    echo "[ok]    hop 2  ferro-ledger-reader trusts the bridge role (not yet exercised)"
  else
    echo "[FAULT] hop 2  ferro-ledger-reader does not trust the bridge role by its current name"
    bad=$((bad + 1))
  fi
fi

# Hop 3: reader -> the data.
if [ -n "$S2" ]; then
  if aws_with_creds "$(echo "$S2" | awk '{print $1}')" "$(echo "$S2" | awk '{print $2}')" "$(echo "$S2" | awk '{print $3}')" \
       s3api get-object --bucket ferro-ledger-archive --key 2026/q3.csv /dev/null >/dev/null 2>&1; then
    echo "[ok]    hop 3  the reader role reads s3://ferro-ledger-archive/2026/q3.csv"
    if aws_with_creds "$(echo "$S2" | awk '{print $1}')" "$(echo "$S2" | awk '{print $2}')" "$(echo "$S2" | awk '{print $3}')" \
         s3api get-object --bucket ferro-ledger-archive --key 2025/q3.csv /dev/null >/dev/null 2>&1; then
      echo "BLOCKER: the reader role can read the 2025 prefix too. The engagement covers 2026 only."
      exit 1
    fi
  else
    echo "[FAULT] hop 3  the reader role cannot read s3://ferro-ledger-archive/2026/q3.csv"
    bad=$((bad + 1))
  fi
else
  if aws_local iam get-role-policy --role-name ferro-ledger-reader --policy-name read-2026 --query PolicyDocument --output json 2>/dev/null \
       | jq -r '.Statement[].Resource' | grep -q 'arn:aws:s3:::ferro-ledger-archive/'; then
    echo "[ok]    hop 3  the reader role's permission names the real bucket (not yet exercised)"
  else
    echo "[FAULT] hop 3  the reader role's permissions do not name the ledger archive bucket"
    bad=$((bad + 1))
  fi
fi

if [ "$bad" -gt 0 ]; then
  echo "$bad hop(s) still broken."
  exit 1
fi
echo "ashgrove-auditor -> ferro-audit-bridge -> ferro-ledger-reader -> q3.csv. Fieldwork can begin; ExternalId and break-glass boundaries held."
