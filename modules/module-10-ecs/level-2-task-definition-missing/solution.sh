#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local ecs register-task-definition --cli-input-json file://harbor-web.json >/dev/null
bash deploy.sh >/dev/null
