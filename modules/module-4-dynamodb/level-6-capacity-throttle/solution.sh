#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for kind in Write Read; do
  aws_local application-autoscaling register-scalable-target --service-namespace dynamodb \
    --resource-id table/pulsewire-readings --scalable-dimension "dynamodb:table:${kind}CapacityUnits" \
    --min-capacity 25 --max-capacity 1000 >/dev/null
  aws_local application-autoscaling put-scaling-policy --service-namespace dynamodb \
    --resource-id table/pulsewire-readings --scalable-dimension "dynamodb:table:${kind}CapacityUnits" \
    --policy-name "pulsewire-${kind}-tracking" --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration \
    "{\"TargetValue\":70.0,\"PredefinedMetricSpecification\":{\"PredefinedMetricType\":\"DynamoDB${kind}CapacityUtilization\"},\"ScaleInCooldown\":300,\"ScaleOutCooldown\":60}" >/dev/null
done
