#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SM="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:brightwave-ticket-triage"
base="$AWS_ENDPOINT_URL/${ACCOUNT_ID}"

# Submit a ticket, wait for the execution, then return the name of the queue that received it.
route_of() {
  local id="$1" prio="$2" arn st q body
  arn="$(aws_local stepfunctions start-execution --state-machine-arn "$SM" \
    --input "{\"ticketId\":\"$id\",\"priority\":\"$prio\"}" --query executionArn --output text)"
  settled() { [ "$(aws_local stepfunctions describe-execution --execution-arn "$arn" --query status --output text)" != "RUNNING" ]; }
  wait_for "execution of $id" 30 settled || return 1
  st="$(aws_local stepfunctions describe-execution --execution-arn "$arn" --query status --output text)"
  if [ "$st" != "SUCCEEDED" ]; then
    echo "Ticket with priority '$prio' ended as $st: $(aws_local stepfunctions describe-execution --execution-arn "$arn" --query '[error,cause]' --output text | cut -c1-220)"
    return 1
  fi
  for q in bw-pager bw-escalations bw-backlog; do
    body="$(aws_local sqs receive-message --queue-url "$base/$q" --max-number-of-messages 10 \
      --wait-time-seconds 0 --visibility-timeout 0 --query 'Messages[].Body' --output text 2>/dev/null || true)"
    case "$body" in *"$id"*) echo "$q"; return 0 ;; esac
  done
  echo "none"
}

stamp="$(date +%s)"
fail=0
check() { # priority expected-queue
  local got
  got="$(route_of "V-$stamp-$1" "$1")" || { echo "$got"; fail=1; return; }
  if [ "$got" != "$2" ]; then
    echo "A ticket with priority '$1' landed in '$got' but belongs in '$2'."
    fail=1
  fi
}

check urgent bw-pager
check high bw-escalations
check normal bw-backlog
check low bw-backlog
check whenever bw-backlog

if [ "$fail" -ne 0 ]; then exit 1; fi
echo "Every priority now has a destination: urgent pages, high escalates, everything else lands in the backlog."
