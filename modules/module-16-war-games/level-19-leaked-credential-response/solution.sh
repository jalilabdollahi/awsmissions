#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. Give CI a fresh credential first, and put it where the pipeline reads it.
aws_local iam create-access-key --user-name cg-build-bot --query 'AccessKey.{id:AccessKeyId,secret:SecretAccessKey}' --output json > newkey.json
aws_local ssm put-parameter --name /cinder/ci/build-bot-credentials --type SecureString --overwrite --value "$(jq -c . newkey.json)" >/dev/null
rm -f newkey.json

# 2. Kill the leaked key (keep the evidence in SSM).
LID="$(aws_local ssm get-parameter --name /cinder/forensics/leaked-key --with-decryption --query Parameter.Value --output text | jq -r .id)"
aws_local iam delete-access-key --user-name cg-build-bot --access-key-id "$LID"

# 3. Remove the attacker's persistence.
for k in $(aws_local iam list-access-keys --user-name cg-support-sync --query 'AccessKeyMetadata[].AccessKeyId' --output text); do
  aws_local iam delete-access-key --user-name cg-support-sync --access-key-id "$k"
done
aws_local iam detach-user-policy --user-name cg-support-sync --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws_local iam delete-user --user-name cg-support-sync
aws_local iam detach-role-policy --role-name cg-audit-helper --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws_local iam delete-role --role-name cg-audit-helper

# 4. Shrink the build identity to artifact uploads.
aws_local iam put-user-policy --user-name cg-build-bot --policy-name ci-everything --policy-document '{
  "Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:PutObject","s3:GetObject"],"Resource":"arn:aws:s3:::cg-build-artifacts/*"}]}'
