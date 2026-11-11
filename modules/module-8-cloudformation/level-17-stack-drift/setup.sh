#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudformation delete-stack --stack-name tern-ingest >/dev/null 2>&1 || true

aws_local cloudformation create-stack --stack-name tern-ingest \
  --template-body "file://$MISSION_DIR/workspace/template.json" >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name tern-ingest

# The 2 a.m. hotfix, applied by hand, outside CloudFormation.
aws_local lambda update-function-configuration --function-name tern-ingest-fn \
  --timeout 30 --memory-size 512 \
  --environment 'Variables={BATCH_SIZE=150,REGION_TAG=north}' >/dev/null
aws_local s3api put-bucket-versioning --bucket tern-ingest-landing \
  --versioning-configuration Status=Enabled

echo "tern-ingest is deployed, and production no longer matches its template."
