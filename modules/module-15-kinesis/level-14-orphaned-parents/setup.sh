#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local kinesis create-stream --stream-name ledger-entries --shard-count 1 >/dev/null
wait_for "stream ledger-entries" 20 aws_local kinesis describe-stream-summary --stream-name ledger-entries

# Each account gets entries seq 1..6; the stream is resharded between the groups.
write_entries() {
  local from="$1" to="$2" seq acct
  seq="$from"
  while [ "$seq" -le "$to" ]; do
    for acct in 1 2 3 4; do
      aws_local kinesis put-record --stream-name ledger-entries --partition-key "acct-$acct" \
        --data "$(printf '{"account":"acct-%s","seq":%s,"cents":%s}' "$acct" "$seq" "$((seq * 100 + acct))" | base64)" >/dev/null
    done
    seq=$((seq + 1))
  done
}
write_entries 1 3
aws_local kinesis update-shard-count --stream-name ledger-entries --target-shard-count 2 --scaling-type UNIFORM_SCALING >/dev/null
write_entries 4 5
aws_local kinesis update-shard-count --stream-name ledger-entries --target-shard-count 4 --scaling-type UNIFORM_SCALING >/dev/null
write_entries 6 6

aws_local iam create-role --role-name ledger-export-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
policy="$(jq -cn --arg acct "$ACCOUNT_ID" '{Version:"2012-10-17",Statement:[
  {Effect:"Allow",Action:["kinesis:ListShards","kinesis:GetShardIterator","kinesis:DescribeStreamSummary","kinesis:DescribeStream"],Resource:"arn:aws:kinesis:us-east-1:\($acct):stream/ledger-entries"},
  {Effect:"Allow",Action:"kinesis:GetRecords",Resource:"*"}]}')"
aws_local iam put-role-policy --role-name ledger-export-role --policy-name read-ledger --policy-document "$policy"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/export.zip" export.py)
aws_local lambda create-function --function-name ledger-export \
  --runtime python3.12 --handler export.handler --timeout 60 \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/ledger-export-role" \
  --zip-file "fileb://$stage/export.zip" >/dev/null

echo "ledger-entries went from 1 to 2 to 4 shards; ledger-export still knows only the first one."
