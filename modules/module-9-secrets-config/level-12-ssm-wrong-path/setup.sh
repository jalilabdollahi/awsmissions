#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local ssm put-parameter --name /lattice/prod/db-host --type String --value "inventory-db.lattice.internal" >/dev/null
aws_local ssm put-parameter --name /lattice/prod/db-user --type String --value "inventory_app" >/dev/null
aws_local ssm put-parameter --name /lattice/prod/db-password --type SecureString --value "Orchid-Kettle-902" >/dev/null
aws_local ssm put-parameter --name /lattice/dev/db-host --type String --value "localhost" >/dev/null

aws_local iam create-user --user-name lattice-svc >/dev/null
aws_local iam put-user-policy --user-name lattice-svc --policy-name read-production-config \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"ssm:GetParameter\",\"ssm:GetParameters\"],\"Resource\":\"arn:aws:ssm:us-east-1:${ACCOUNT_ID}:parameter/lattice/production/*\"}]}"

echo "Config lives under /lattice/prod; the service reads /lattice/production."
