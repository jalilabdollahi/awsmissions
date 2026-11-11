#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic_exists() {
  aws_local sns list-topics --query 'Topics[].TopicArn' --output text | tr '\t' '\n' | grep -q ":$1\$"
}

status="$(aws_local cloudformation describe-stacks --stack-name marlow-catalog \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
case "$status" in
  CREATE_COMPLETE|UPDATE_COMPLETE) ;;
  "") echo "marlow-catalog does not exist."; exit 1 ;;
  *) echo "marlow-catalog is in $status."; exit 1 ;;
esac
env="$(aws_local cloudformation describe-stacks --stack-name marlow-catalog \
  --query "Stacks[0].Parameters[?ParameterKey=='Environment'].ParameterValue" --output text)"
if [ "$env" != "prod" ]; then
  echo "The stack runs with Environment='$env'. Production must stay Environment=prod; fix the template logic, not the input."
  exit 1
fi

if [ "$(aws_local s3api get-bucket-versioning --bucket marlow-prod-catalog --query Status --output text 2>/dev/null || true)" != "Enabled" ]; then
  echo "marlow-prod-catalog does not keep object versions yet."
  exit 1
fi
if ! topic_exists marlow-prod-pager; then
  echo "Production has no pager topic (marlow-prod-pager)."
  exit 1
fi
if topic_exists marlow-prod-debug; then
  echo "A debug topic (marlow-prod-debug) still exists in production; it is for developer sandboxes only."
  exit 1
fi

# Behaviour of the template itself: deploy the stack's current template as a dev sandbox.
tmp="$(mktemp)"
trap 'rm -f "$tmp"; aws_local cloudformation delete-stack --stack-name marlow-condition-probe >/dev/null 2>&1 || true' EXIT
aws_local cloudformation get-template --stack-name marlow-catalog --output json \
  | jq -r '.TemplateBody | if type=="string" then . else tojson end' > "$tmp"
aws_local cloudformation delete-stack --stack-name marlow-condition-probe >/dev/null 2>&1 || true
if ! aws_local cloudformation create-stack --stack-name marlow-condition-probe \
     --template-body "file://$tmp" --parameters ParameterKey=Environment,ParameterValue=dev >/dev/null 2>&1; then
  echo "The stack's template cannot be deployed with Environment=dev."
  exit 1
fi
if ! wait_for "dev probe stack" 40 sh -c \
  "aws --endpoint-url=$AWS_ENDPOINT_URL cloudformation describe-stacks --stack-name marlow-condition-probe --query 'Stacks[0].StackStatus' --output text | grep -q CREATE_COMPLETE"; then
  echo "The template could not be deployed as a dev sandbox."
  exit 1
fi
if ! topic_exists marlow-dev-debug; then
  echo "Production is right now, but a developer sandbox (Environment=dev) no longer gets its debug topic."
  exit 1
fi
if topic_exists marlow-dev-pager; then
  echo "A developer sandbox must not page anyone, yet Environment=dev creates a pager topic."
  exit 1
fi
if [ "$(aws_local s3api get-bucket-versioning --bucket marlow-dev-catalog --query Status --output text 2>/dev/null || true)" = "Enabled" ]; then
  echo "Sandboxes should not pay for versioned buckets; versioning is a production-only setting."
  exit 1
fi

echo "marlow-catalog behaves: production is versioned and paged, sandboxes get the debug topic."
