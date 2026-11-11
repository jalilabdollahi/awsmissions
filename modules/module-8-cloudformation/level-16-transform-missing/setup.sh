#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudformation delete-stack --stack-name parcelhub-notifier >/dev/null 2>&1 || true

# Where the courier team's build job drops packaged code (kept for the story;
# the notifier uses inline code).
aws_local s3 mb s3://parcelhub-build-artifacts >/dev/null
echo "The Parcelhub SAM template is in your workspace; the stack has not been deployed."
