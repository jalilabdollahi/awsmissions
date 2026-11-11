#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3api put-object --bucket quill-manifest-offload \
  --key manifests/2026-11-12.json --body payload/manifest.json >/dev/null

queue="$(aws_local sqs get-queue-url --queue-name quill-manifest-jobs --query QueueUrl --output text)"
aws_local sqs send-message --queue-url "$queue" \
  --message-body '{"bucket":"quill-manifest-offload","key":"manifests/2026-11-12.json","contentType":"application/json"}'
