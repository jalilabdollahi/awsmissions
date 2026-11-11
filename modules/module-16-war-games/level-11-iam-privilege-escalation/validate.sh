#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

A="arn:aws:iam::${ACCOUNT_ID}"
DEPLOYER="$A:role/qf-ci-deployer"
stamp="$(date +%s)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
printf 'def handler(e, c):\n    return {"v": 2}\n' > "$tmp/app.py"
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],'app.py')" "$tmp/app.zip" "$tmp/app.py"
ci() { aws_as_role "$DEPLOYER" qf-ci-bot "" "$@"; }
broken=0
echo "PT-2026-014 retest"

if ! aws_local iam get-role --role-name qf-ci-deployer >/dev/null 2>&1; then
  echo "qf-ci-deployer was deleted. The pipeline needs it; reduce its permissions instead."
  exit 1
fi

# --- Part 1: the pipeline must still work -------------------------------------------------
rc=0
ci s3api put-object --bucket qf-build-artifacts --key "builds/$stamp.zip" --body "$tmp/app.zip" >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 98 ]; then echo "qf-ci-bot can no longer assume qf-ci-deployer. Leave the trust relationship alone."; exit 1; fi
dutiesfail=0
[ "$rc" -eq 0 ] || { echo "[DUTY ] uploading build artifacts to qf-build-artifacts is broken"; dutiesfail=1; }
ci lambda update-function-code --function-name qf-payments-api --zip-file "fileb://$tmp/app.zip" >/dev/null 2>&1 \
  || { echo "[DUTY ] updating the code of qf-payments-api is broken"; dutiesfail=1; }
ci lambda create-function --function-name "qf-probe-$stamp" --runtime python3.12 --handler app.handler \
  --role "$A:role/qf-svc-lambda-exec" --zip-file "fileb://$tmp/app.zip" >/dev/null 2>&1 \
  || { echo "[DUTY ] creating a function with the standard qf-svc-lambda-exec role is broken"; dutiesfail=1; }
aws_local lambda delete-function --function-name "qf-probe-$stamp" >/dev/null 2>&1 || true
if [ "$dutiesfail" -ne 0 ]; then
  echo "The pipeline would break tonight. Close the escalation paths without removing what CI legitimately needs."
  exit 1
fi
echo "[ok]    duties  uploads, code deploys and standard function creation still work"

# --- Part 2: the escalation paths ---------------------------------------------------------
# Path 1: mint a new role and make it an admin.
if ci iam create-role --role-name "qf-ci-forged-$stamp" --assume-role-policy-document \
     '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1; then
  if ci iam attach-role-policy --role-name "qf-ci-forged-$stamp" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess >/dev/null 2>&1; then
    echo "[FAULT] path 1  CI can create a role and attach AdministratorAccess to it"
    broken=$((broken + 1))
  else
    echo "[ok]    path 1  CI can no longer make an admin role"
  fi
  aws_local iam detach-role-policy --role-name "qf-ci-forged-$stamp" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess >/dev/null 2>&1 || true
  aws_local iam delete-role --role-name "qf-ci-forged-$stamp" >/dev/null 2>&1 || true
else
  echo "[ok]    path 1  CI can no longer make an admin role"
fi

# Path 2: hand an existing privileged role to a new function.
if ci lambda create-function --function-name "qf-evil-$stamp" --runtime python3.12 --handler app.handler \
     --role "$A:role/qf-platform-admin-role" --zip-file "fileb://$tmp/app.zip" >/dev/null 2>&1; then
  echo "[FAULT] path 2  CI can create a function that runs as qf-platform-admin-role"
  broken=$((broken + 1))
  aws_local lambda delete-function --function-name "qf-evil-$stamp" >/dev/null 2>&1 || true
else
  echo "[ok]    path 2  CI cannot pass the platform admin role to a service"
fi

# Path 3: mint credentials for someone else.
if k="$(ci iam create-access-key --user-name qf-platform-admin --query AccessKey.AccessKeyId --output text 2>/dev/null)" && [ -n "$k" ]; then
  echo "[FAULT] path 3  CI can create access keys for qf-platform-admin"
  broken=$((broken + 1))
  aws_local iam delete-access-key --user-name qf-platform-admin --access-key-id "$k" >/dev/null 2>&1 || true
else
  echo "[ok]    path 3  CI cannot create keys for other users"
fi

# Path 4: rewrite its own permissions.
if ci iam put-role-policy --role-name qf-ci-deployer --policy-name self-grant --policy-document \
     '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"*","Resource":"*"}]}' >/dev/null 2>&1; then
  echo "[FAULT] path 4  CI can write new inline policies onto its own role"
  broken=$((broken + 1))
  aws_local iam delete-role-policy --role-name qf-ci-deployer --policy-name self-grant >/dev/null 2>&1 || true
else
  echo "[ok]    path 4  CI cannot rewrite its own permissions"
fi

if [ "$broken" -gt 0 ]; then
  echo "$broken escalation path(s) remain open."
  exit 1
fi
echo "No escalation path left and the pipeline still ships. Finding PT-2026-014 can be closed."
