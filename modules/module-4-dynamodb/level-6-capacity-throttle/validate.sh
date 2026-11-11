#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

T=pulsewire-readings
mode="$(aws_local dynamodb describe-table --table-name "$T" \
  --query 'Table.BillingModeSummary.BillingMode' --output text 2>/dev/null || echo MISSING)"
case "$mode" in
  PAY_PER_REQUEST)
    echo "The table was switched to on-demand. Finance requires provisioned mode (reserved capacity): keep it PROVISIONED and let auto scaling move the units."
    exit 1 ;;
  MISSING)
    echo "pulsewire-readings does not exist."
    exit 1 ;;
esac

check_dim() {
  local dim="$1" label="$2" metric="$3" row
  row="$(aws_local application-autoscaling describe-scalable-targets --service-namespace dynamodb \
    --resource-ids "table/$T" --scalable-dimension "$dim" \
    --query 'ScalableTargets[0].[MinCapacity,MaxCapacity]' --output text 2>/dev/null || true)"
  if [ -z "$row" ] || [ "$row" = "None" ]; then
    echo "No auto scaling target is registered for $label capacity of $T."
    exit 1
  fi
  local min max
  min="$(printf '%s' "$row" | awk '{print $1}')"; max="$(printf '%s' "$row" | awk '{print $2}')"
  if [ "$max" -lt 500 ]; then
    echo "$label scaling can only reach $max units; the nightly burst needs headroom of at least 500."
    exit 1
  fi
  if [ "$min" -lt 20 ]; then
    echo "$label scaling may drop to $min units; the floor must be at least 20 or the 02:00 burst arrives at an under-sized table."
    exit 1
  fi
  local pol
  pol="$(aws_local application-autoscaling describe-scaling-policies --service-namespace dynamodb \
    --resource-id "table/$T" --scalable-dimension "$dim" \
    --query 'ScalingPolicies[?PolicyType==`TargetTrackingScaling`].[TargetTrackingScalingPolicyConfiguration.TargetValue,TargetTrackingScalingPolicyConfiguration.PredefinedMetricSpecification.PredefinedMetricType]' \
    --output text 2>/dev/null || true)"
  if [ -z "$pol" ] || [ "$pol" = "None" ]; then
    echo "$label capacity has a scalable target but no target-tracking scaling policy, so nothing will ever scale it."
    exit 1
  fi
  local target mtype
  target="$(printf '%s' "$pol" | awk 'NR==1{print int($1)}')"
  mtype="$(printf '%s' "$pol" | awk 'NR==1{print $2}')"
  if [ "$mtype" != "$metric" ]; then
    echo "The $label policy tracks $mtype; it should track $metric."
    exit 1
  fi
  if [ "$target" -lt 30 ] || [ "$target" -gt 80 ]; then
    echo "The $label policy aims for $target% utilisation. Pick something between 30 and 80 percent: near 100 leaves no room for bursts, very low wastes money."
    exit 1
  fi
}

check_dim dynamodb:table:WriteCapacityUnits write DynamoDBWriteCapacityUtilization
check_dim dynamodb:table:ReadCapacityUnits read DynamoDBReadCapacityUtilization

if ! aws_local dynamodb put-item --table-name "$T" \
  --item '{"turbineId":{"S":"wt-check"},"readAt":{"N":"1"},"rpm":{"N":"1"}}' >/dev/null 2>&1; then
  echo "Writes to the table fail."
  exit 1
fi
aws_local dynamodb delete-item --table-name "$T" --key '{"turbineId":{"S":"wt-check"},"readAt":{"N":"1"}}' >/dev/null
echo "pulsewire-readings is still provisioned, and both read and write capacity now track demand."
