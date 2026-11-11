#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

bad=0
echo "Credential-leak response check (SEC-INC-0402)"

# Collateral damage first.
for u in cg-build-bot cg-dev-alice; do
  if ! aws_local iam get-user --user-name "$u" >/dev/null 2>&1; then
    echo "User $u was deleted. CI and staff depend on them; rotate credentials, don't remove identities."
    exit 1
  fi
done
probe="$(mktemp)"; trap 'rm -f "$probe"' EXIT; echo "build $(date +%s)" > "$probe"

leaked="$(aws_local ssm get-parameter --name /cinder/forensics/leaked-key --with-decryption --query Parameter.Value --output text 2>/dev/null || true)"
if [ -z "$leaked" ]; then echo "The forensic record /cinder/forensics/leaked-key was removed; keep it as evidence."; exit 1; fi
LID="$(printf '%s' "$leaked" | jq -r .id)"; LSEC="$(printf '%s' "$leaked" | jq -r .secret)"

# 1. Is the leaked key still alive?
if aws_with_creds "$LID" "$LSEC" "" sts get-caller-identity >/dev/null 2>&1; then
  echo "[FAULT] leak     the leaked key still authenticates against the account"
  bad=$((bad + 1))
else
  echo "[ok]    leak     the leaked key no longer works"
fi

# 2. Does CI have a working, different credential?
cred="$(aws_local ssm get-parameter --name /cinder/ci/build-bot-credentials --with-decryption --query Parameter.Value --output text 2>/dev/null || true)"
CID="$(printf '%s' "$cred" | jq -r '.id // empty' 2>/dev/null || true)"; CSEC="$(printf '%s' "$cred" | jq -r '.secret // empty' 2>/dev/null || true)"
ci_ok=0
if [ -z "$CID" ] || [ "$CID" = "$LID" ]; then
  echo "[FAULT] ci       the pipeline's credential parameter still holds the leaked key (or nothing usable)"
  bad=$((bad + 1))
elif aws_with_creds "$CID" "$CSEC" "" s3api put-object --bucket cg-build-artifacts --key "builds/release-$(date +%s).zip" --body "$probe" >/dev/null 2>&1; then
  echo "[ok]    ci       CI can upload builds with its new credential"
  ci_ok=1
else
  echo "[FAULT] ci       the credential in the pipeline's parameter cannot upload to cg-build-artifacts"
  bad=$((bad + 1))
fi

# 3. Attacker persistence.
if aws_local iam get-user --user-name cg-support-sync >/dev/null 2>&1; then
  echo "[FAULT] persist  the hidden user cg-support-sync still exists"
  bad=$((bad + 1))
else
  echo "[ok]    persist  the hidden user is gone"
fi
if aws_local iam get-role --role-name cg-audit-helper >/dev/null 2>&1; then
  echo "[FAULT] persist  the role cg-audit-helper (trusting a foreign account) still exists"
  bad=$((bad + 1))
else
  echo "[ok]    persist  the foreign-trust role is gone"
fi

# 4. Blast radius of the build identity (tested with its own new credential).
if [ "$ci_ok" -eq 1 ]; then
  if aws_with_creds "$CID" "$CSEC" "" s3api get-object --bucket cg-player-data --key players.csv /dev/null >/dev/null 2>&1 \
     || aws_with_creds "$CID" "$CSEC" "" iam list-users >/dev/null 2>&1; then
    echo "[FAULT] scope    the build identity can still read player data or manage IAM"
    bad=$((bad + 1))
  else
    echo "[ok]    scope    the build identity can upload artifacts but not read player data or touch IAM"
  fi
else
  if aws_local iam get-user-policy --user-name cg-build-bot --policy-name ci-everything >/dev/null 2>&1; then
    echo "[FAULT] scope    cg-build-bot still carries the broad ci-everything policy"
    bad=$((bad + 1))
  else
    echo "[ok]    scope    the broad inline policy is gone (the new one will be exercised once CI has a credential)"
  fi
fi

if [ "$bad" -gt 0 ]; then
  echo "$bad item(s) of the response are still open."
  exit 1
fi
echo "Leaked key dead, CI shipping with a fresh key, attacker persistence removed, build identity least-privileged. Close the incident and schedule the postmortem."
