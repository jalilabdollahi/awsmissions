#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Copy every parameter under /lattice/prod to /lattice/production, keeping types.
aws_local ssm get-parameters-by-path --path /lattice/prod --recursive --with-decryption \
  --query 'Parameters[].[Name,Type,Value]' --output text | while IFS="$(printf '\t')" read -r name ptype value; do
  [ -z "$name" ] && continue
  aws_local ssm put-parameter --name "/lattice/production/${name##*/}" --type "$ptype" \
    --value "$value" >/dev/null
done
