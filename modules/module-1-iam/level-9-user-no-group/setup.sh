#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://nimbus-curated >/dev/null
aws_local s3 mb s3://nimbus-raw-landing >/dev/null
seed="$(mktemp)"
trap 'rm -f "$seed"' EXIT
printf 'day,events\n2025-11-10,88213\n' > "$seed"
aws_local s3api put-object --bucket nimbus-curated --key daily/events.csv --body "$seed" >/dev/null
aws_local s3api put-object --bucket nimbus-raw-landing --key landing/dump-0001.json --body "$seed" >/dev/null

aws_local iam create-group --group-name nimbus-analysts >/dev/null
aws_local iam put-group-policy --group-name nimbus-analysts --policy-name curated-read \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:ListBucket"],"Resource":"arn:aws:s3:::nimbus-curated"},{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::nimbus-curated/*"}]}'

aws_local iam create-group --group-name nimbus-platform-admins >/dev/null
aws_local iam attach-group-policy --group-name nimbus-platform-admins \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws_local iam create-group --group-name nimbus-contractors >/dev/null
aws_local iam put-group-policy --group-name nimbus-contractors --policy-name raw-read \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:ListBucket"],"Resource":"arn:aws:s3:::nimbus-raw-landing"},{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::nimbus-raw-landing/*"}]}'

# Existing colleagues, so the groups are not empty.
aws_local iam create-user --user-name nimbus-marcus >/dev/null
aws_local iam add-user-to-group --group-name nimbus-analysts --user-name nimbus-marcus
aws_local iam create-user --user-name nimbus-jo >/dev/null
aws_local iam add-user-to-group --group-name nimbus-platform-admins --user-name nimbus-jo

aws_local iam create-user --user-name nimbus-priya >/dev/null

echo "nimbus-priya exists, belongs to no group, and can do nothing."
