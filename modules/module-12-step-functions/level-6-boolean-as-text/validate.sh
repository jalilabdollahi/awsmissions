#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SM="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:quillon-dispatch"
express_q="$AWS_ENDPOINT_URL/${ACCOUNT_ID}/quillon-express-lane"
standard_q="$AWS_ENDPOINT_URL/${ACCOUNT_ID}/quillon-standard-lane"
aws_local sqs purge-queue --queue-url "$express_q" >/dev/null 2>&1 || true
aws_local sqs purge-queue --queue-url "$standard_q" >/dev/null 2>&1 || true

# Dispatch one parcel and report which lane it ended up in.
lane_for() {
  local parcel="$1" payload="$2" ex st
  ex="$(aws_local stepfunctions start-execution --state-machine-arn "$SM" --input "$payload" \
    --query executionArn --output text)"
  ended() { [ "$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)" != "RUNNING" ]; }
  wait_for "dispatch of $parcel" 30 ended || return 1
  st="$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)"
  if [ "$st" != "SUCCEEDED" ]; then
    echo "FAILED: parcel $parcel made the execution end as $st ($(aws_local stepfunctions describe-execution --execution-arn "$ex" --query error --output text))"
    return 0
  fi
  local lane
  for lane in express standard; do
    local url="$express_q"; [ "$lane" = "standard" ] && url="$standard_q"
    if aws_local sqs receive-message --queue-url "$url" --max-number-of-messages 10 --visibility-timeout 0 \
         --query 'Messages[].Body' --output text | grep -q "$parcel"; then
      echo "$lane"; return 0
    fi
  done
  echo "nowhere"
}

n="$(date +%s)"
problems=0
expect() { # parcel payload expected-lane description
  local got
  got="$(lane_for "$1" "$2")"
  if [ "$got" != "$3" ]; then
    echo "Parcel $4 -> $got (expected the $3 lane)."
    problems=$((problems + 1))
  fi
}

expect "QV-$n-A" "{\"parcelId\":\"QV-$n-A\",\"express\":true,\"kg\":1}" express "with express=true"
expect "QV-$n-B" "{\"parcelId\":\"QV-$n-B\",\"express\":false,\"kg\":1}" standard "with express=false"
expect "QV-$n-C" "{\"parcelId\":\"QV-$n-C\",\"kg\":4}" standard "without an express field"

if [ "$problems" -ne 0 ]; then exit 1; fi
echo "Express parcels take the express lane; everything else, flagless partner parcels included, goes standard."
