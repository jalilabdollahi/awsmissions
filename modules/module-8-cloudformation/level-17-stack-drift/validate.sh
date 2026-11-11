#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

status="$(aws_local cloudformation describe-stacks --stack-name tern-ingest \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
case "$status" in
  CREATE_COMPLETE|UPDATE_COMPLETE) ;;
  "") echo "The tern-ingest stack no longer exists."; exit 1 ;;
  *) echo "tern-ingest is in $status."; exit 1 ;;
esac

# The hotfix itself must survive.
live="$(aws_local lambda get-function-configuration --function-name tern-ingest-fn --output json 2>/dev/null || true)"
if [ -z "$live" ]; then
  echo "The function tern-ingest-fn is gone."
  exit 1
fi
live_timeout="$(printf '%s' "$live" | jq -r '.Timeout')"
live_memory="$(printf '%s' "$live" | jq -r '.MemorySize')"
live_batch="$(printf '%s' "$live" | jq -r '.Environment.Variables.BATCH_SIZE // "none"')"
live_tag="$(printf '%s' "$live" | jq -r '.Environment.Variables.REGION_TAG // "none"')"
if [ "$live_timeout" != "30" ] || [ "$live_memory" != "512" ] || [ "$live_batch" != "150" ] || [ "$live_tag" != "north" ]; then
  echo "The live function no longer carries the incident hotfix (timeout $live_timeout, memory $live_memory, BATCH_SIZE $live_batch, REGION_TAG $live_tag). Do not revert the fix; teach the template about it."
  exit 1
fi
if [ "$(aws_local s3api get-bucket-versioning --bucket tern-ingest-landing --query Status --output text 2>/dev/null || true)" != "Enabled" ]; then
  echo "Versioning on tern-ingest-landing was switched off again; the hotfix included it."
  exit 1
fi

# What the stack believes, as CloudFormation stored it.
template="$(aws_local cloudformation get-template --stack-name tern-ingest --output json \
  | jq -c '.TemplateBody | if type=="string" then (try fromjson catch null) else . end')"
if [ -z "$template" ] || [ "$template" = "null" ]; then
  echo "The stack's template is not JSON any more; keep submitting it as JSON so it can be compared."
  exit 1
fi

fn_key="$(printf '%s' "$template" | jq -r '[.Resources | to_entries[] | select(.value.Type=="AWS::Lambda::Function") | .key] | first // empty')"
bkt_key="$(printf '%s' "$template" | jq -r '[.Resources | to_entries[] | select(.value.Type=="AWS::S3::Bucket") | .key] | first // empty')"
if [ -z "$fn_key" ] || [ -z "$bkt_key" ]; then
  echo "The stack's template must still define both the function and the bucket."
  exit 1
fi

t_timeout="$(printf '%s' "$template" | jq -r --arg k "$fn_key" '.Resources[$k].Properties.Timeout // "unset"')"
t_memory="$(printf '%s' "$template" | jq -r --arg k "$fn_key" '.Resources[$k].Properties.MemorySize // "unset"')"
t_batch="$(printf '%s' "$template" | jq -r --arg k "$fn_key" '.Resources[$k].Properties.Environment.Variables.BATCH_SIZE // "unset"')"
t_tag="$(printf '%s' "$template" | jq -r --arg k "$fn_key" '.Resources[$k].Properties.Environment.Variables.REGION_TAG // "unset"')"
t_version="$(printf '%s' "$template" | jq -r --arg k "$bkt_key" '.Resources[$k].Properties.VersioningConfiguration.Status // "unset"')"

fn_drift=0
bkt_drift=0
[ "$t_timeout" = "$live_timeout" ] || fn_drift=$((fn_drift + 1))
[ "$t_memory" = "$live_memory" ] || fn_drift=$((fn_drift + 1))
[ "$t_batch" = "$live_batch" ] || fn_drift=$((fn_drift + 1))
[ "$t_tag" = "$live_tag" ] || fn_drift=$((fn_drift + 1))
[ "$t_version" = "Enabled" ] || bkt_drift=$((bkt_drift + 1))

if [ $((fn_drift + bkt_drift)) -gt 0 ]; then
  echo "The stack's template still disagrees with reality: $fn_drift setting(s) on the function, $bkt_drift on the bucket."
  exit 1
fi

echo "The template now describes exactly what runs in production, and the hotfix is intact."
