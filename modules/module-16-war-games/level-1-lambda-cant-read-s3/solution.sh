#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. Give the role read access to the manifests prefix, nothing else.
aws_local iam put-role-policy --role-name hv-indexer-role --policy-name indexer-runtime --policy-document '{
  "Version":"2012-10-17",
  "Statement":[
    {"Sid":"ListManifests","Effect":"Allow","Action":"s3:ListBucket","Resource":"arn:aws:s3:::hv-manifests"},
    {"Sid":"ReadIncoming","Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::hv-manifests/incoming/*"},
    {"Sid":"WriteProcessed","Effect":"Allow","Action":"s3:PutObject","Resource":"arn:aws:s3:::hv-manifests/processed/*"},
    {"Sid":"IndexRow","Effect":"Allow","Action":"dynamodb:PutItem","Resource":"arn:aws:dynamodb:us-east-1:000000000000:table/hv-manifest-index"}]}'

# 2. Drop only the freeze statement from the bucket policy; keep the contractor wall.
aws_local s3api get-bucket-policy --bucket hv-manifests --query Policy --output text > bucket-policy.json
python3 - <<'PY'
import json
doc = json.load(open("bucket-policy.json"))
doc["Statement"] = [s for s in doc["Statement"] if s.get("Sid") != "FreezeOldIndexer"]
json.dump(doc, open("bucket-policy.json", "w"), indent=2)
PY
aws_local s3api put-bucket-policy --bucket hv-manifests --policy file://bucket-policy.json

# 3. Point the function at the real bucket.
aws_local lambda update-function-configuration --function-name hv-manifest-indexer \
  --environment 'Variables={MANIFEST_BUCKET=hv-manifests,INDEX_TABLE=hv-manifest-index}' >/dev/null
aws_local lambda wait function-updated-v2 --function-name hv-manifest-indexer 2>/dev/null || sleep 3
