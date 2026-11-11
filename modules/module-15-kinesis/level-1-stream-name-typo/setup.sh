#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Role first: the function can only be created once the role exists.
trust='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws_local iam create-role --role-name thermo-ingest-role --assume-role-policy-document "$trust" >/dev/null

# The role may append to any stream whose name starts with "thermowave-".
grant="$(jq -cn --arg arn "arn:aws:kinesis:us-east-1:${ACCOUNT_ID}:stream/thermowave-*" \
  '{Version:"2012-10-17",Statement:[{Effect:"Allow",Action:["kinesis:PutRecord","kinesis:PutRecords"],Resource:$arn}]}')"
aws_local iam put-role-policy --role-name thermo-ingest-role --policy-name append-readings --policy-document "$grant"

aws_local kinesis create-stream --stream-name thermowave-readings --shard-count 2 >/dev/null
wait_for "stream thermowave-readings" 20 aws_local kinesis describe-stream-summary --stream-name thermowave-readings

bundle="$(mktemp -d)"
trap 'rm -rf "$bundle"' EXIT
cp "$MISSION_DIR/workspace/ingest.py" "$bundle/"
(cd "$bundle" && zip -q code.zip ingest.py)

# Monday's release shipped a mistyped stream name together with the channel flag.
env_vars='Variables={STREAM_NAME=thermowave-reading,FIRMWARE_CHANNEL=stable}'
aws_local lambda create-function --function-name thermo-ingest --handler ingest.handler \
  --runtime python3.12 --environment "$env_vars" \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/thermo-ingest-role" \
  --zip-file "fileb://$bundle/code.zip" >/dev/null

echo "thermo-ingest is deployed, the stream exists, and readings are not arriving."
