#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

bad=0
echo "Partner API triage (INC-4417)"

API="$(aws_local apigateway get-rest-apis --query "items[?name=='qm-catalog'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API" ] || [ "$API" = "None" ]; then
  echo "The qm-catalog REST API no longer exists. Repair it instead of deleting it."
  exit 1
fi
if ! aws_local lambda get-function --function-name qm-catalog-api >/dev/null 2>&1; then
  echo "Lambda qm-catalog-api no longer exists."
  exit 1
fi
KEYVAL="$(aws_local apigateway get-api-keys --name-query qm-partner-key --include-values --query 'items[0].value' --output text 2>/dev/null || true)"
KEYID="$(aws_local apigateway get-api-keys --name-query qm-partner-key --query 'items[0].id' --output text 2>/dev/null || true)"
if [ -z "$KEYVAL" ] || [ "$KEYVAL" = "None" ]; then
  echo "The partner API key qm-partner-key is gone; partners would need a new key."
  exit 1
fi
URL="$AWS_ENDPOINT_URL/restapis/$API/prod/_user_request_/books"

# Symptom 1: does the contract stage exist?
stages="$(aws_local apigateway get-stages --rest-api-id "$API" --query 'item[].stageName' --output text 2>/dev/null || true)"
case " $(echo "$stages" | tr '\t' ' ') " in
  *" prod "*) echo "[ok]    symptom 1  stage prod exists" ;;
  *) echo "[FAULT] symptom 1  partners call /prod/... but this API has no such stage (stages: ${stages:-none})"; bad=$((bad + 1)) ;;
esac

# Symptom 2: does the integration point at a function that exists?
RES="$(aws_local apigateway get-resources --rest-api-id "$API" --query "items[?path=='/books'].id | [0]" --output text 2>/dev/null || true)"
uri="$(aws_local apigateway get-integration --rest-api-id "$API" --resource-id "$RES" --http-method GET --query uri --output text 2>/dev/null || true)"
target="$(printf '%s' "$uri" | sed -n 's#.*:function:\([A-Za-z0-9_-]*\).*#\1#p')"
if [ -n "$target" ] && aws_local lambda get-function --function-name "$target" >/dev/null 2>&1; then
  echo "[ok]    symptom 2  GET /books integrates with an existing function ($target)"
else
  echo "[FAULT] symptom 2  GET /books integration targets '${target:-nothing}', which is not a function in this account"
  bad=$((bad + 1))
fi

# Symptom 3: can the function run at all?
out="$(mktemp)"
aws_local lambda invoke --function-name qm-catalog-api --cli-binary-format raw-in-base64-out --payload '{}' "$out" >/dev/null 2>"$out.err" || true
if grep -qi 'TooManyRequests\|Rate Exceeded' "$out.err"; then
  echo "[FAULT] symptom 3  invoking qm-catalog-api is throttled"
  bad=$((bad + 1))
else
  echo "[ok]    symptom 3  qm-catalog-api accepts invocations"
fi
rm -f "$out" "$out.err"

# Symptom 4: is the partner key allowed on the prod stage?
plans="$(aws_local apigateway get-usage-plans --output json 2>/dev/null || echo '{"items":[]}')"
covered=0
for pid in $(printf '%s' "$plans" | jq -r --arg api "$API" '.items[] | select([.apiStages[]? | select(.apiId == $api and .stage == "prod")] | length > 0) | .id'); do
  if aws_local apigateway get-usage-plan-keys --usage-plan-id "$pid" --query "items[?id=='$KEYID'] | length(@)" --output text 2>/dev/null | grep -q '^1$'; then
    covered=1
  fi
done
if [ "$covered" -eq 1 ]; then
  echo "[ok]    symptom 4  partner key is covered by a usage plan on prod"
else
  echo "[FAULT] symptom 4  no usage plan ties the partner key to the prod stage"
  bad=$((bad + 1))
fi

if [ "$bad" -gt 0 ]; then
  echo "$bad symptom(s) remain. Live partner request skipped."
  exit 1
fi

code="$(curl -s -o /tmp/qm-body.$$ -w '%{http_code}' -H "x-api-key: $KEYVAL" "$URL" || true)"
body="$(cat /tmp/qm-body.$$ 2>/dev/null || true)"; rm -f /tmp/qm-body.$$
if [ "$code" != "200" ] || ! printf '%s' "$body" | jq -e '.books | length > 0' >/dev/null 2>&1; then
  echo "A partner request returned HTTP $code: $(printf '%s' "$body" | head -c 160)"
  echo "The configuration looks right, so check whether the latest changes were actually deployed to prod."
  exit 1
fi
nokey="$(curl -s -o /dev/null -w '%{http_code}' "$URL" || true)"
if [ "$nokey" = "200" ]; then
  echo "Requests without an API key now succeed. The key requirement is part of the partner contract."
  exit 1
fi
echo "GET /prod/books with the partner key returns the catalogue (HTTP 200); keyless calls are rejected ($nokey). Partners are back."
