#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SM="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:saffron-signup"

signup() { # email name plan boxes
  local ex
  ex="$(aws_local stepfunctions start-execution --state-machine-arn "$SM" \
    --input "{\"email\":\"$1\",\"fullName\":\"$2\",\"plan\":\"$3\",\"boxes\":$4}" \
    --query executionArn --output text)"
  finished() { [ "$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)" != "RUNNING" ]; }
  wait_for "signup execution" 30 finished || return 1
  local st
  st="$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)"
  if [ "$st" != "SUCCEEDED" ]; then
    echo "Signup for $1 ended as $st: $(aws_local stepfunctions describe-execution --execution-arn "$ex" --query '[error,cause]' --output text | cut -c1-200)"
    return 1
  fi
}

stamp="$(date +%s)"
e1="noor.$stamp@example.org"
e2="pavel.$stamp@example.org"
signup "$e1" "Noor Haddad" family 3 || exit 1
signup "$e2" "Pavel Sokol" solo 1 || exit 1

fetch() { # email -> item JSON (empty when absent)
  aws_local dynamodb get-item --table-name saffron-subscribers \
    --key "{\"email\":{\"S\":\"$1\"}}" --output json --query 'Item' 2>/dev/null || true
}
item1="$(fetch "$e1")"
item2="$(fetch "$e2")"

if [ -z "$item1" ] || [ "$item1" = "null" ] || [ -z "$item2" ] || [ "$item2" = "null" ]; then
  echo "A new subscriber could not be found by their email address. Rows are being written under a different key."
  exit 1
fi

want1="Welcome to Saffron, Noor Haddad! Your family plan starts with 3 boxes."
want2="Welcome to Saffron, Pavel Sokol! Your solo plan starts with 1 boxes."
got1="$(printf '%s' "$item1" | jq -r '.welcomeLine.S // ""')"
got2="$(printf '%s' "$item2" | jq -r '.welcomeLine.S // ""')"
if [ "$got1" != "$want1" ] || [ "$got2" != "$want2" ]; then
  echo "The rows exist but welcomeLine is not the finished sentence. Stored: '$got1'"
  exit 1
fi

if [ "$(printf '%s' "$item1" | jq -r '.boxesPerWeek.N // ""')" != "3" ] || [ "$(printf '%s' "$item1" | jq -r '.plan.S // ""')" != "family" ]; then
  echo "plan or boxesPerWeek were damaged while fixing the item. Keep them as they were."
  exit 1
fi

echo "Each signup now creates its own row under the real email, with a proper welcome line."
