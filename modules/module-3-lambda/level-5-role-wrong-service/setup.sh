#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://lumen-thumb-source >/dev/null
for n in 1 2 3; do
  printf 'raw image %s' "$n" | aws_local s3 cp - "s3://lumen-thumb-source/raw/IMG_000$n.cr3" >/dev/null
done
printf 'done' | aws_local s3 cp - "s3://lumen-thumb-source/thumbs/IMG_0000.jpg" >/dev/null

aws_local iam create-user --user-name ci-deployer >/dev/null

# The role was copied from the render farm's EC2 instance role.
aws_local iam create-role --role-name lumen-thumb-scanner \
  --assume-role-policy-document "file://$MISSION_DIR/workspace/trust.json" >/dev/null
aws_local iam put-role-policy --role-name lumen-thumb-scanner --policy-name read-raw-uploads \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:ListBucket","Resource":"arn:aws:s3:::lumen-thumb-source"}]}'

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/scan.zip" thumbnailer.py)
aws_local lambda create-function --function-name thumbnail-scanner \
  --runtime python3.12 --handler thumbnailer.scan \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/lumen-thumb-scanner" \
  --zip-file "fileb://$stage/scan.zip" >/dev/null

echo "thumbnail-scanner runs as lumen-thumb-scanner, a role copied from an EC2 template."
