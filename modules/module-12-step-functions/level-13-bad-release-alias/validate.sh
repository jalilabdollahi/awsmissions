#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SM="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:marlin-limit-check"
ALIAS="${SM}:live"

if ! aws_local stepfunctions describe-state-machine-alias --state-machine-alias-arn "$ALIAS" >/dev/null 2>&1; then
  echo "The alias marlin-limit-check:live is gone. The payments platform calls that exact ARN."
  exit 1
fi

weighted="$(aws_local stepfunctions describe-state-machine-alias --state-machine-alias-arn "$ALIAS" \
  --query 'length(routingConfiguration[?weight>`0`])' --output text)"
if [ "$weighted" != "1" ]; then
  echo "The alias splits traffic between $weighted versions. A bank guard cannot send some large payments to an unchecked version: move the whole alias to one version."
  exit 1
fi

# Decide through the alias, exactly as the payments platform does.
decide() { # txId amount currency
  local ex st
  ex="$(aws_local stepfunctions start-execution --state-machine-arn "$ALIAS" \
    --input "{\"txId\":\"$1\",\"amount\":$2,\"currency\":\"$3\"}" --query executionArn --output text)"
  over() { [ "$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)" != "RUNNING" ]; }
  wait_for "execution $1" 30 over || { echo "TIMEOUT"; return 0; }
  st="$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)"
  if [ "$st" != "SUCCEEDED" ]; then
    echo "FAILED($(aws_local stepfunctions describe-execution --execution-arn "$ex" --query 'error' --output text))"
    return 0
  fi
  aws_local stepfunctions describe-execution --execution-arn "$ex" --query output --output text | jq -r '.decision // "none"'
}

tag="$(date +%s)"
bad=0
verify() { # amount currency expected description
  local got
  got="$(decide "TX-$tag-$bad-$2" "$1" "$2")"
  if [ "$got" != "$3" ]; then
    echo "$4: the alias answered '$got', expected $3."
    bad=$((bad + 1))
  fi
}

verify 2500 EUR REVIEW "EUR 2500"
verify 900 GBP REVIEW "GBP 900 (1080 EUR after conversion)"
verify 500 USD APPROVE "USD 500 (450 EUR after conversion)"
verify 1000 EUR REVIEW "EUR 1000, exactly on the limit"
verify 999.99 EUR APPROVE "EUR 999.99"

if [ "$bad" -ne 0 ]; then exit 1; fi
echo "The live alias applies the EUR 1,000 limit after conversion, on one version, and every payment completes."
