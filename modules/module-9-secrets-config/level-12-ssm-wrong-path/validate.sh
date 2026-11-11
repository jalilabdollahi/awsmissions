#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# The service's boot sequence: three single-parameter reads, as lattice-svc.
read_as_service() {
  aws_as_user lattice-svc ssm get-parameter --name "/lattice/production/$1" --with-decryption \
    --query Parameter.Value --output text 2>&1
}

host="$(read_as_service db-host)" || {
  echo "lattice-svc cannot read /lattice/production/db-host: $(printf '%s' "$host" | tail -1)"
  exit 1
}
user="$(read_as_service db-user)" || {
  echo "lattice-svc cannot read /lattice/production/db-user: $(printf '%s' "$user" | tail -1)"
  exit 1
}
password="$(read_as_service db-password)" || {
  echo "lattice-svc cannot read /lattice/production/db-password: $(printf '%s' "$password" | tail -1)"
  exit 1
}

if [ "$host" != "inventory-db.lattice.internal" ]; then
  echo "/lattice/production/db-host does not hold the database host."
  exit 1
fi
if [ "$user" != "inventory_app" ]; then
  echo "/lattice/production/db-user does not hold the database user."
  exit 1
fi
if [ "$password" != "Orchid-Kettle-902" ]; then
  echo "/lattice/production/db-password does not hold the database password."
  exit 1
fi

ptype="$(aws_local ssm describe-parameters \
  --parameter-filters "Key=Name,Option=Equals,Values=/lattice/production/db-password" \
  --query 'Parameters[0].Type' --output text 2>/dev/null || true)"
if [ "$ptype" != "SecureString" ]; then
  echo "/lattice/production/db-password is a '$ptype' parameter; the password must stay encrypted."
  exit 1
fi

# Other teams still use /lattice/prod; the service must not get access to it.
if aws_as_user lattice-svc ssm get-parameter --name /lattice/prod/db-host >/dev/null 2>&1; then
  echo "lattice-svc can now read /lattice/prod. Fix the data, not the service's permissions."
  exit 1
fi
if [ -z "$(aws_local ssm get-parameter --name /lattice/prod/db-host --query Parameter.Value --output text 2>/dev/null || true)" ]; then
  echo "The /lattice/prod parameters used by other teams were removed."
  exit 1
fi

echo "The service reads host, user and an encrypted password from /lattice/production, and /lattice/prod is untouched."
