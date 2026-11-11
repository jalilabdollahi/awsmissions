#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam add-user-to-group --group-name nimbus-analysts --user-name nimbus-priya
