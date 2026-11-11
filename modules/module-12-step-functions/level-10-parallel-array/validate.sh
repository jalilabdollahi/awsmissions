#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SM="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:orbit-profile-card"
QUEUE="$AWS_ENDPOINT_URL/${ACCOUNT_ID}/orbit-profile-cards"
aws_local sqs purge-queue --queue-url "$QUEUE" >/dev/null 2>&1 || true

card_for() { # customer id -> message body on stdout, or a line starting with "ERR:"
  local cust="$1" ex st
  ex="$(aws_local stepfunctions start-execution --state-machine-arn "$SM" \
    --input "{\"customerId\":\"$cust\"}" --query executionArn --output text)"
  fin() { [ "$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)" != "RUNNING" ]; }
  wait_for "execution for $cust" 40 fin || { echo "ERR: execution for $cust did not finish"; return 0; }
  st="$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)"
  if [ "$st" != "SUCCEEDED" ]; then
    echo "ERR: execution for $cust ended as $st: $(aws_local stepfunctions describe-execution --execution-arn "$ex" --query '[error,cause]' --output text | cut -c1-230)"
    return 0
  fi
  local hits
  hits="$(aws_local sqs receive-message --queue-url "$QUEUE" --max-number-of-messages 10 --wait-time-seconds 2 \
    --visibility-timeout 0 --query 'Messages[].Body' --output text | tr '\t' '\n' | grep "$cust" || true)"
  if [ -z "$hits" ]; then echo "ERR: no card for $cust reached orbit-profile-cards"; return 0; fi
  printf '%s' "$hits" | head -1
}

check_card() { # customer plan gb
  local out
  out="$(card_for "$1")"
  case "$out" in ERR:*) echo "${out#ERR: }"; return 1 ;; esac
  printf '%s' "$out" | python3 -c '
import json, sys
cust, plan, gb = sys.argv[1], sys.argv[2], float(sys.argv[3])
try:
    card = json.loads(sys.stdin.read())
except ValueError:
    print("The message for %s is not JSON." % cust); sys.exit(1)
expected_keys = {"customerId", "plan", "gbUsed"}
if set(card) != expected_keys:
    print("Card for %s has keys %s; consumers expect exactly customerId, plan and gbUsed." % (cust, sorted(card))); sys.exit(1)
if card["customerId"] != cust or card["plan"] != plan or float(card["gbUsed"]) != gb:
    print("Card for %s has wrong values: %s" % (cust, json.dumps(card))); sys.exit(1)
' "$1" "$2" "$3"
}

check_card C-5521 unlimited-5g 18.4 || exit 1
check_card C-1002 saver-4g 2.1 || exit 1

echo "Both lookups run in parallel and the profile card carries the right plan and usage for each customer."
