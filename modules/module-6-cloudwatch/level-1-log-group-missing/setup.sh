#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# A sibling service's group survived the clean-up; the checkout API's did not.
aws_local logs create-log-group --log-group-name /swiftpost/locker-firmware
aws_local logs create-log-stream --log-group-name /swiftpost/locker-firmware --log-stream-name fw-0001

echo "Only /swiftpost/locker-firmware exists. The checkout API has nowhere to write."
