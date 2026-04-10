#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local sqs create-queue --queue-name mission-queue.fifo --attributes FifoQueue=true,ContentBasedDeduplication=false >/dev/null 2>&1 || true
echo "Broken FIFO queue created: content-based deduplication is disabled"
