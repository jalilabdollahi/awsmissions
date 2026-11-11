#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TG=$(aws_local elbv2 describe-target-groups --names brewline-orders --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [ -z "$TG" ] || [ "$TG" = "None" ]; then
  echo "The target group brewline-orders is gone. Repair it instead of replacing it."
  exit 1
fi

# Guard rails first: what is the check configured to do?
read -r hc_enabled hc_path hc_matcher hc_port < <(aws_local elbv2 describe-target-groups --target-group-arns "$TG" \
  --query 'TargetGroups[0].[HealthCheckEnabled,HealthCheckPath,Matcher.HttpCode,HealthCheckPort]' --output text)
if [ "$hc_enabled" != "True" ] && [ "$hc_enabled" != "true" ]; then
  echo "Health checks are switched off. That hides the problem instead of fixing it."
  exit 1
fi
python3 - "$hc_matcher" <<'PY' || exit 1
import sys
for part in sys.argv[1].split(","):
    part = part.strip()
    hi = int(part.split("-")[-1]) if part else 0
    if hi >= 300:
        print("The success codes (%s) accept redirects or errors. A health check that treats HTTP 404 or 5xx as healthy tells you nothing; point it at an endpoint that really returns 200." % sys.argv[1])
        sys.exit(1)
PY

count=$(aws_local elbv2 describe-target-health --target-group-arn "$TG" --query 'length(TargetHealthDescriptions)' --output text)
if [ "$count" != "2" ]; then
  echo "brewline-orders should still have its two instances registered (found $count)."
  exit 1
fi

good() {
  [ "$(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" --output text)" = "2" ]
}
failing() {
  [ "$(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='unhealthy'])" --output text)" = "2" ]
}
# Poll up to 45s; give up early once both targets have stayed unhealthy for 12s in a row.
waited=0; streak=0
while [ "$waited" -lt 45 ]; do
  good && break
  if failing; then streak=$((streak + 1)); else streak=0; fi
  [ "$streak" -ge 12 ] && break
  sleep 1; waited=$((waited + 1))
done
if ! good; then
  echo "Targets are not healthy yet. Health check: path $hc_path, success codes $hc_matcher, port $hc_port. States: $(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State,TargetHealth.Reason]' --output text | tr '\t\n' ' ;')"
  exit 1
fi
echo "Both brewline-orders targets pass a strict health check on $hc_path (success codes $hc_matcher)."
