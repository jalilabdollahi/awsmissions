#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local sqs create-queue --queue-name mission-queue >/dev/null 2>&1 || true
echo "Broken state prepared: app is using the wrong queue URL"
