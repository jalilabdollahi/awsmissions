#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

BUCKET=helixia-lab-inbox
run="$(date +%s)"
hit_key="results/sample-$run.json"
txt_key="results/sample-$run.txt"
scan_key="scans/sample-$run.json"

indexed() {
  aws_local dynamodb get-item --table-name lab-result-index \
    --key "{\"object_key\":{\"S\":\"$1\"}}" --query 'Item.object_key.S' --output text 2>/dev/null | grep -qx "$1"
}

# Real behaviour: upload three files and see which ones get indexed.
echo '{"patient":"anon","marker":"A1"}' | aws_local s3 cp - "s3://$BUCKET/$hit_key" >/dev/null
echo 'free text note' | aws_local s3 cp - "s3://$BUCKET/$txt_key" >/dev/null
echo '{"raw":"scan metadata"}' | aws_local s3 cp - "s3://$BUCKET/$scan_key" >/dev/null

if ! wait_for "indexer to process $hit_key" 20 indexed "$hit_key"; then
  if aws_local s3api get-bucket-notification-configuration --bucket "$BUCKET" --output json 2>/dev/null | jq -e '(.LambdaFunctionConfigurations // []) | length > 0' >/dev/null; then
    echo "A trigger exists, but uploading $hit_key (a .json under results/) did not get it indexed. Check the target function, the event type and the filters."
  else
    echo "Uploading $hit_key produced no index entry: the bucket has no trigger at all."
  fi
  exit 1
fi

sleep 4
if indexed "$txt_key"; then
  echo "A .txt file was indexed. The trigger needs a suffix filter so only .json results are processed."
  exit 1
fi
if indexed "$scan_key"; then
  echo "A file under scans/ was indexed. The trigger needs a prefix filter so only results/ is processed."
  exit 1
fi

echo "New .json files under results/ are indexed automatically, and scans/ and other files are left alone."
