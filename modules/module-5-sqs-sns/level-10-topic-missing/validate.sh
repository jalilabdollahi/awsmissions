#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local sns get-topic-attributes --topic-arn arn:aws:sns:us-east-1:000000000000:mission-topic >/dev/null
echo "success"
