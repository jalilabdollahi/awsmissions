#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TG=$(aws_local elbv2 describe-target-groups --names fathomly-api --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [ -z "$TG" ] || [ "$TG" = "None" ]; then
  echo "The target group fathomly-api is gone."
  exit 1
fi
read -r enabled path interval timeout unhealthy matcher < <(aws_local elbv2 describe-target-groups --target-group-arns "$TG" \
  --query 'TargetGroups[0].[HealthCheckEnabled,HealthCheckPath,HealthCheckIntervalSeconds,HealthCheckTimeoutSeconds,UnhealthyThresholdCount,Matcher.HttpCode]' --output text)

if [ "$enabled" != "True" ] && [ "$enabled" != "true" ]; then
  echo "Health checks are disabled. That is not a fix."
  exit 1
fi
if [ "$timeout" -ge "$interval" ]; then
  echo "Timeout ($timeout s) must be shorter than the interval ($interval s); the load balancer needs a pause between checks."
  exit 1
fi
if [ "$matcher" != "200" ]; then
  echo "Keep the success code strict (200). The checks pass for the right reason or not at all."
  exit 1
fi
detect=$((interval * unhealthy))
if [ "$detect" -gt 120 ]; then
  echo "A real outage would take $detect seconds to detect (interval $interval s x $unhealthy failures). Keep it near two minutes or less."
  exit 1
fi
if [ "$(aws_local elbv2 describe-target-health --target-group-arn "$TG" --query 'length(TargetHealthDescriptions)' --output text)" != "2" ]; then
  echo "fathomly-api should still have its two instances registered."
  exit 1
fi

# If the deep check is kept, the timeout must really exceed its response time (about 7s).
if [ "$path" = "/health" ] && [ "$timeout" -lt 9 ]; then
  echo "Path /health takes about 7 seconds to answer, but the timeout is $timeout s; the check still cannot finish in time."
  exit 1
fi

two_good() {
  [ "$(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" --output text)" = "2" ]
}
failing() {
  [ "$(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='unhealthy'])" --output text)" = "2" ]
}
n=0; stuck=0
while [ "$n" -lt 60 ]; do
  two_good && break
  if failing; then stuck=$((stuck + 1)); else stuck=0; fi
  [ "$stuck" -ge $((interval + 8)) ] && break
  sleep 1; n=$((n + 1))
done
if ! two_good; then
  echo "Targets are still not healthy (path $path, timeout ${timeout}s, interval ${interval}s): $(aws_local elbv2 describe-target-health --target-group-arn "$TG" --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State,TargetHealth.Reason]' --output text | tr '\t\n' ' ;')"
  exit 1
fi
echo "Both targets are healthy with a valid check (path $path, ${timeout}s timeout every ${interval}s, outage detected within ${detect}s)."
