#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local autoscaling update-auto-scaling-group --auto-scaling-group-name parcelway-asg \
  --launch-template 'LaunchTemplateName=parcelway-lt,Version=$Latest'
aws_local autoscaling start-instance-refresh --auto-scaling-group-name parcelway-asg \
  --preferences MinHealthyPercentage=50
