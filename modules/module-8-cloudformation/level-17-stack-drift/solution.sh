#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. Read reality.
live="$(aws_local lambda get-function-configuration --function-name tern-ingest-fn --output json)"
timeout="$(printf '%s' "$live" | jq '.Timeout')"
memory="$(printf '%s' "$live" | jq '.MemorySize')"
vars="$(printf '%s' "$live" | jq -c '.Environment.Variables')"
versioning="$(aws_local s3api get-bucket-versioning --bucket tern-ingest-landing --query Status --output text)"

# 2. Teach the template about it.
jq --argjson t "$timeout" --argjson m "$memory" --argjson v "$vars" --arg s "$versioning" '
  .Resources.IngestFunction.Properties.Timeout = $t
  | .Resources.IngestFunction.Properties.MemorySize = $m
  | .Resources.IngestFunction.Properties.Environment.Variables = $v
  | .Resources.LandingBucket.Properties.VersioningConfiguration = {Status: $s}
' template.json > template.new && mv template.new template.json

# 3. Roll the template out; the live values are already what it now says.
aws_local cloudformation update-stack --stack-name tern-ingest \
  --template-body file://template.json >/dev/null
aws_local cloudformation wait stack-update-complete --stack-name tern-ingest
