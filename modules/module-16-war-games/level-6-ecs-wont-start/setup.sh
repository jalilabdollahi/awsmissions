#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam create-role --role-name ledger-task-exec --assume-role-policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local ecs create-cluster --cluster-name ledger-prod >/dev/null

# Revision 1: private mirror image (unreachable) and the wrapper's variable under the wrong name.
aws_local ecs register-task-definition --family ledger-web --network-mode awsvpc \
  --requires-compatibilities FARGATE --cpu 256 --memory 512 \
  --execution-role-arn "arn:aws:iam::${ACCOUNT_ID}:role/ledger-task-exec" \
  --container-definitions '[{
    "name":"web",
    "image":"registry.ledgerco.invalid/ledger-web:2026.11",
    "essential":true,
    "portMappings":[{"containerPort":80,"protocol":"tcp"}],
    "environment":[{"name":"DATABASE_HOST","value":"ledger-db.internal"}],
    "entryPoint":["sh","-c"],
    "command":["test -n \"$DB_HOST\" || { echo \"DB_HOST is not set\"; exit 3; }; exec nginx -g \"daemon off;\""]
  }]' >/dev/null

aws_local ecs create-service --cluster ledger-prod --service-name ledger-web --task-definition ledger-web:1 \
  --desired-count 0 --launch-type FARGATE \
  --network-configuration 'awsvpcConfiguration={subnets=[subnet-default-us-east-1-a,subnet-default-us-east-1-b]}' >/dev/null

echo "INC-6120 is open: ledger-web has no tasks and revision 1 will not start."
