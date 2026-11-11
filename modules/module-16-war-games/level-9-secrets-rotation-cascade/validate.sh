#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/juniper-claims-role"
bad=0
echo "INC-9004 credential chain"

if ! aws_local secretsmanager describe-secret --secret-id juniper/prod/db-credentials >/dev/null 2>&1; then
  echo "juniper/prod/db-credentials is gone. Don't delete it again."
  exit 1
fi

# Guardrail: the role must not become a secrets reader.
rc=0
aws_as_role "$ROLE_ARN" jn-oncall "" secretsmanager get-secret-value --secret-id juniper/prod/billing-api-key >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 98 ]; then echo "jn-oncall cannot assume the claims role any more; leave the trust policy alone."; exit 1; fi
if [ "$rc" -eq 0 ]; then
  echo "BLOCKER: the claims role can now read juniper/prod/billing-api-key, which belongs to another team."
  exit 1
fi

# Chain 1: can the role read this application's secret?
if aws_as_role "$ROLE_ARN" jn-oncall "" secretsmanager get-secret-value --secret-id juniper/prod/db-credentials >/dev/null 2>&1; then
  echo "[ok]    chain 1  the role can read juniper/prod/db-credentials"
else
  echo "[FAULT] chain 1  Secrets Manager refuses the role when it asks for juniper/prod/db-credentials"
  bad=$((bad + 1))
fi

# Chain 2: does the function look up something that exists?
sid="$(aws_local lambda get-function-configuration --function-name juniper-claims-api --query 'Environment.Variables.SECRET_ID' --output text 2>/dev/null || echo None)"
if [ "$sid" != "None" ] && aws_local secretsmanager describe-secret --secret-id "$sid" >/dev/null 2>&1; then
  echo "[ok]    chain 2  the function's SECRET_ID resolves to a live secret"
else
  echo "[FAULT] chain 2  the function's SECRET_ID does not resolve to an existing secret"
  bad=$((bad + 1))
fi

# Chain 3: does the current version carry what the database accepts?
live="$(aws_local ssm get-parameter --name /juniper/db/live-password --with-decryption --query Parameter.Value --output text)"
cur="$(aws_local secretsmanager get-secret-value --secret-id juniper/prod/db-credentials --version-stage AWSCURRENT --query SecretString --output text 2>/dev/null | jq -r '.password // empty' 2>/dev/null || true)"
if [ "$cur" = "$live" ]; then
  echo "[ok]    chain 3  the current secret version matches the database"
else
  echo "[FAULT] chain 3  the current secret version holds a password the database no longer accepts"
  bad=$((bad + 1))
fi

if [ "$bad" -gt 0 ]; then
  echo "$bad link(s) of the chain are broken."
  exit 1
fi

out="$(mktemp)"
aws_local lambda invoke --function-name juniper-claims-api --cli-binary-format raw-in-base64-out --payload '{}' "$out" >"$out.meta" 2>&1 || true
if [ -n "$(jq -r '.FunctionError // empty' "$out.meta" 2>/dev/null)" ] || [ "$(jq -r '.db // empty' "$out" 2>/dev/null)" != "authenticated" ]; then
  echo "Each link looks right but the function still fails: $(jq -r '.errorMessage // empty' "$out" | cut -c1-150)"
  rm -f "$out" "$out.meta"
  exit 1
fi
rm -f "$out" "$out.meta"
echo "juniper-claims-api authenticated against the database. The portal is serving claims again."
