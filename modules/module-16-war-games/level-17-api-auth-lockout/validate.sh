#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

bad=0
echo "Partner API triage (PX-318)"

API="$(aws_local apigateway get-rest-apis --query "items[?name=='pelican-partner-api'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API" ] || [ "$API" = "None" ]; then echo "The pelican-partner-api API is gone."; exit 1; fi
TOKEN="$(aws_local ssm get-parameter --name /pelican/partner-token --query Parameter.Value --output text)"
RES="$(aws_local apigateway get-resources --rest-api-id "$API" --query "items[?path=='/lockers'].id | [0]" --output text)"
URL="$AWS_ENDPOINT_URL/restapis/$API/live/_user_request_/lockers"

# Auth type of the method.
m="$(aws_local apigateway get-method --rest-api-id "$API" --resource-id "$RES" --http-method GET --output json 2>/dev/null || echo '{}')"
atype="$(printf '%s' "$m" | jq -r '.authorizationType // "NONE"')"
aid="$(printf '%s' "$m" | jq -r '.authorizerId // ""')"
if [ "$atype" = "NONE" ]; then
  echo "BLOCKER: GET /lockers has no authorization at all. A partner API without authentication is a data leak."
  exit 1
fi
if [ "$atype" = "CUSTOM" ] && [ -n "$aid" ]; then
  echo "[ok]    gate 1  GET /lockers is protected by the token authorizer"
else
  echo "[FAULT] gate 1  GET /lockers uses authorization type $atype, not the token authorizer partners were promised"
  bad=$((bad + 1))
fi

# Where does the authorizer look for the token?
if [ -n "$aid" ]; then
  src="$(aws_local apigateway get-authorizer --rest-api-id "$API" --authorizer-id "$aid" --query identitySource --output text 2>/dev/null || echo none)"
else
  src="$(aws_local apigateway get-authorizers --rest-api-id "$API" --query 'items[0].identitySource' --output text 2>/dev/null || echo none)"
fi
if [ "$(printf '%s' "$src" | tr 'A-Z' 'a-z')" = "method.request.header.authorization" ]; then
  echo "[ok]    gate 2  the authorizer reads the token from the Authorization header"
else
  echo "[FAULT] gate 2  the authorizer looks for the token in '$src', not where partners send it"
  bad=$((bad + 1))
fi

# The authorizer function itself.
out="$(mktemp)"
aws_local lambda invoke --function-name pl-token-auth --cli-binary-format raw-in-base64-out \
  --payload "{\"authorizationToken\":\"$TOKEN\",\"methodArn\":\"arn:aws:execute-api:us-east-1:${ACCOUNT_ID}:$API/live/GET/lockers\"}" "$out" >"$out.meta" 2>&1 || true
eff="$(jq -r '.policyDocument.Statement[0].Effect // empty' "$out" 2>/dev/null || true)"
if [ "$eff" = "Allow" ]; then
  echo "[ok]    gate 3  the authorizer function can verify a correct token"
else
  echo "[FAULT] gate 3  the authorizer function cannot verify a correct token: $(jq -r '.errorMessage // "no Allow returned"' "$out" 2>/dev/null | cut -c1-110)"
  bad=$((bad + 1))
fi
aws_local lambda invoke --function-name pl-token-auth --cli-binary-format raw-in-base64-out \
  --payload "{\"authorizationToken\":\"wrong-token\",\"methodArn\":\"arn:aws:execute-api:us-east-1:${ACCOUNT_ID}:$API/live/GET/lockers\"}" "$out" >/dev/null 2>&1 || true
if [ "$(jq -r '.policyDocument.Statement[0].Effect // empty' "$out" 2>/dev/null)" = "Allow" ]; then
  echo "BLOCKER: the authorizer allows a wrong token."
  exit 1
fi

# The backend function.
aws_local lambda invoke --function-name pl-lockers-api --cli-binary-format raw-in-base64-out --payload '{}' "$out" >"$out.meta" 2>&1 || true
if [ "$(jq -r '.statusCode // empty' "$out" 2>/dev/null)" = "200" ]; then
  echo "[ok]    gate 4  the backend can list lockers"
else
  echo "[FAULT] gate 4  the backend cannot list lockers: $(jq -r '.errorMessage // "no 200 returned"' "$out" 2>/dev/null | cut -c1-110)"
  bad=$((bad + 1))
fi
rm -f "$out" "$out.meta"

if [ "$bad" -gt 0 ]; then
  echo "$bad gate(s) still broken. No live partner call yet."
  exit 1
fi

code="$(curl -s -o /tmp/pl-body.$$ -w '%{http_code}' -H "Authorization: $TOKEN" "$URL" || true)"
body="$(cat /tmp/pl-body.$$ 2>/dev/null || true)"; rm -f /tmp/pl-body.$$
if [ "$code" != "200" ] || ! printf '%s' "$body" | jq -e '.lockers | length >= 2' >/dev/null 2>&1; then
  echo "A partner call with the right token returned HTTP $code: $(printf '%s' "$body" | head -c 140)"
  echo "Each gate checks out on its own, so check that the stage serves the latest API definition."
  exit 1
fi
nt="$(curl -s -o /dev/null -w '%{http_code}' "$URL" || true)"
wt="$(curl -s -o /dev/null -w '%{http_code}' -H 'Authorization: not-the-token' "$URL" || true)"
if [ "$nt" = "200" ] || [ "$wt" = "200" ]; then
  echo "Calls without a token or with a wrong token succeed (HTTP $nt / $wt). Authentication must still reject them."
  exit 1
fi
echo "Partner call: HTTP 200 with the lockers; no token gives HTTP $nt and a wrong token HTTP $wt. Partners are unblocked."
