#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='ticketdash-api'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "ticketdash-api does not exist."
  exit 1
fi

stage="$(aws_local apigateway get-stage --rest-api-id "$API_ID" --stage-name v2 --output json 2>/dev/null || true)"
if [ -z "$stage" ]; then
  echo "Stage v2 of ticketdash-api does not exist; it must stay the live stage."
  exit 1
fi

verdict="$(printf '%s' "$stage" | python3 -c '
import json, sys
ms = json.load(sys.stdin).get("methodSettings", {})
d = ms.get("*/*", {})
rate, burst = float(d.get("throttlingRateLimit", -1)), int(d.get("throttlingBurstLimit", -1))
if rate <= 0 or burst <= 0:
    print("zero:%s/%s" % (rate, burst)); sys.exit()
if rate < 50 or rate > 1000:
    print("defaultrate:%s" % rate); sys.exit()
if burst < rate or burst > 2000:
    print("defaultburst:%s" % burst); sys.exit()
c = None
for key, val in ms.items():
    if key.endswith("/POST") and "checkout" in key:
        c = val
if c is None:
    print("nocheckout"); sys.exit()
cr, cb = float(c.get("throttlingRateLimit", -1)), int(c.get("throttlingBurstLimit", -1))
if cr <= 0 or cr > 20 or cb <= 0 or cb > 40:
    print("checkout:%s/%s" % (cr, cb)); sys.exit()
print("ok")
')"
case "$verdict" in
  ok) ;;
  zero:*) echo "The stage default is still ${verdict#zero:} (rate/burst). A limit of zero blocks every request."; exit 1 ;;
  defaultrate:*) echo "Default rate limit ${verdict#defaultrate:} is outside 50..1000 requests per second."; exit 1 ;;
  defaultburst:*) echo "Default burst ${verdict#defaultburst:} must be at least the rate and at most 2000."; exit 1 ;;
  nocheckout) echo "POST /checkout has no throttling override of its own. The payment provider cannot take the stage-wide default."; exit 1 ;;
  checkout:*) echo "POST /checkout throttling is ${verdict#checkout:} (rate/burst); it must be 1..20 per second with a burst of at most 40."; exit 1 ;;
esac

base="$AWS_ENDPOINT_URL/restapis/$API_ID/v2/_user_request_"
c1="$(curl -s --max-time 60 -o /dev/null -w '%{http_code}' "$base/events" || true)"
c2="$(curl -s --max-time 60 -o /dev/null -w '%{http_code}' -X POST -d '{}' "$base/checkout" || true)"
if [ "$c1" != "200" ] || [ "$c2" != "200" ]; then
  echo "Routes must keep answering: GET /events=$c1, POST /checkout=$c2."
  exit 1
fi
echo "Stage v2 serves traffic with a default budget and a tighter one for checkout."
