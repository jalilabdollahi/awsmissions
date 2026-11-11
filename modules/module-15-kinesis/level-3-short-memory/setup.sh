#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local kinesis create-stream --stream-name meter-reads --shard-count 1 >/dev/null
wait_for "stream meter-reads" 20 aws_local kinesis describe-stream-summary --stream-name meter-reads

# A few reads that are already in the stream and must survive the fix.
for meter in 4471 4472 4473; do
  aws_local kinesis put-record --stream-name meter-reads --partition-key "meter-$meter" \
    --data "$(printf '{"meter":"%s","kwh":3.2,"seed":true}' "$meter" | base64)" >/dev/null
done

echo "meter-reads holds today's reads and forgets everything older than the default window."
