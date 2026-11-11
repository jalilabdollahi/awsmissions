#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=pixelcart-feature-flags
aws_local s3api put-bucket-versioning --bucket "$B" --versioning-configuration Status=Enabled

# Inspect each real (non-null) version and restore the one with the good flags.
good=""
for vid in $(aws_local s3api list-object-versions --bucket "$B" --prefix flags.json \
    --query 'Versions[?VersionId!=`null`].VersionId' --output text); do
  aws_local s3api get-object --bucket "$B" --key flags.json --version-id "$vid" candidate.json >/dev/null
  if grep -q '"rollout": 50' candidate.json; then good="$vid"; fi
done
rm -f candidate.json
aws_local s3api copy-object --bucket "$B" --key flags.json \
  --copy-source "$B/flags.json?versionId=$good" >/dev/null
