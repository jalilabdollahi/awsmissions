#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local ecs update-service --cluster tidepool --service tidepool-web --task-definition tidepool-web:1 \
  --deployment-configuration 'deploymentCircuitBreaker={enable=true,rollback=true},maximumPercent=200,minimumHealthyPercent=100' >/dev/null
