#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/corvid-checkout"

read_param() {
  aws_as_role "$ROLE_ARN" corvid-runner "" ssm get-parameter --name "$1" \
    --query Parameter.Value --output text 2>&1
}

host="$(read_param /corvid/checkout/db-host)" || {
  echo "As corvid-checkout, reading /corvid/checkout/db-host failed: $(printf '%s' "$host" | tail -1)"
  exit 1
}
port="$(read_param /corvid/checkout/db-port)" || {
  echo "As corvid-checkout, reading /corvid/checkout/db-port failed: $(printf '%s' "$port" | tail -1)"
  exit 1
}

recorded="$(aws_local secretsmanager get-secret-value --secret-id corvid/checkout/db-credentials \
  --query SecretString --output text)"
if [ "$host" != "$(printf '%s' "$recorded" | jq -r .host)" ]; then
  echo "/corvid/checkout/db-host holds '$host', which is not the host recorded for the checkout database."
  exit 1
fi
if [ "$port" != "$(printf '%s' "$recorded" | jq -r .port)" ]; then
  echo "/corvid/checkout/db-port holds '$port', which is not the port recorded for the checkout database."
  exit 1
fi

echo "The checkout role reads the database host and port from Parameter Store."
