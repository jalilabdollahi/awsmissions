#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

U=portal-acme
T=crmly-contacts

as_u() { aws_as_user "$U" "$@"; }
expect_ok() {
  local what="$1"; shift
  local out
  if ! out="$(as_u "$@" 2>&1)"; then
    echo "portal-acme can no longer $what: $(printf '%s' "$out" | tail -1)"
    exit 1
  fi
}
expect_denied() {
  local msg="$1"; shift
  if as_u "$@" >/dev/null 2>&1; then
    echo "$msg"
    exit 1
  fi
}

expect_ok "query its own contacts" dynamodb query --table-name "$T" \
  --key-condition-expression 'tenantId = :t' --expression-attribute-values '{":t":{"S":"acme"}}'
expect_ok "read one of its contacts" dynamodb get-item --table-name "$T" \
  --key '{"tenantId":{"S":"acme"},"contactId":{"S":"c-1"}}'
expect_ok "create a contact for acme" dynamodb put-item --table-name "$T" \
  --item '{"tenantId":{"S":"acme"},"contactId":{"S":"c-new"},"fullName":{"S":"Probe"}}'
expect_ok "delete a contact of acme" dynamodb delete-item --table-name "$T" \
  --key '{"tenantId":{"S":"acme"},"contactId":{"S":"c-new"}}'

expect_denied "portal-acme can still query other tenants' contacts (globex)." dynamodb query --table-name "$T" \
  --key-condition-expression 'tenantId = :t' --expression-attribute-values '{":t":{"S":"globex"}}'
expect_denied "portal-acme can still read a globex contact by key." dynamodb get-item --table-name "$T" \
  --key '{"tenantId":{"S":"globex"},"contactId":{"S":"c-1"}}'
expect_denied "portal-acme can still write into globex's partition." dynamodb put-item --table-name "$T" \
  --item '{"tenantId":{"S":"globex"},"contactId":{"S":"evil"},"fullName":{"S":"Mallory"}}'
expect_denied "portal-acme can still delete globex contacts." dynamodb delete-item --table-name "$T" \
  --key '{"tenantId":{"S":"globex"},"contactId":{"S":"c-2"}}'
expect_denied "portal-acme can still Scan the table, which returns every tenant's rows. A leading-key condition cannot restrict a scan, so the action itself has to go." \
  dynamodb scan --table-name "$T"

left="$(aws_local dynamodb get-item --table-name "$T" --key '{"tenantId":{"S":"globex"},"contactId":{"S":"c-2"}}' --query 'Item.fullName.S' --output text)"
if [ "$left" != "Yusuf Demir" ]; then
  echo "A globex contact was damaged while validating."
  exit 1
fi
echo "portal-acme sees and changes only acme's contacts."
