#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

aws_local s3 mb s3://cg-build-artifacts >/dev/null
aws_local s3 mb s3://cg-player-data >/dev/null
printf 'player,email\np-1,a@example.com\n' > "$tmp/pd.csv"
aws_local s3 cp "$tmp/pd.csv" s3://cg-player-data/players.csv >/dev/null

aws_local iam create-user --user-name cg-dev-alice >/dev/null
aws_local iam put-user-policy --user-name cg-dev-alice --policy-name artifacts-read --policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:ListBucket","s3:GetObject"],"Resource":["arn:aws:s3:::cg-build-artifacts","arn:aws:s3:::cg-build-artifacts/*"]}]}'

# The CI user, with the 2024 "just make the pipeline work" policy.
aws_local iam create-user --user-name cg-build-bot >/dev/null
aws_local iam put-user-policy --user-name cg-build-bot --policy-name ci-everything --policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:*","iam:*"],"Resource":"*"}]}'
leaked="$(aws_local iam create-access-key --user-name cg-build-bot --query 'AccessKey.{id:AccessKeyId,secret:SecretAccessKey}' --output json)"
aws_local ssm put-parameter --name /cinder/forensics/leaked-key --type SecureString --value "$(printf '%s' "$leaked" | jq -c .)" >/dev/null
aws_local ssm put-parameter --name /cinder/ci/build-bot-credentials --type SecureString --value "$(printf '%s' "$leaked" | jq -c .)" >/dev/null

# Attacker persistence, created with the leaked key's iam:* rights.
aws_local iam create-user --user-name cg-support-sync >/dev/null
aws_local iam attach-user-policy --user-name cg-support-sync --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws_local iam create-access-key --user-name cg-support-sync >/dev/null
aws_local iam create-role --role-name cg-audit-helper --assume-role-policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::999999999999:root"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam attach-role-policy --role-name cg-audit-helper --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

echo "SEC-INC-0402 is open: the CI key is public and the attacker left doors behind."
