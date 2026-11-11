#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

cfg="$(aws_local lambda get-function-url-config --function-name invite-landing --output json 2>/dev/null || true)"
if [ -z "$cfg" ]; then
  echo "invite-landing no longer has a function URL. Fix the existing one."
  exit 1
fi

auth="$(printf '%s' "$cfg" | jq -r '.AuthType')"
if [ "$auth" != "NONE" ]; then
  echo "The invite-landing URL still uses AuthType $auth: browsers cannot sign requests, so visitors are refused."
  exit 1
fi

# AuthType NONE alone is not enough: a public principal must also be allowed to invoke through the URL.
policy="$(aws_local lambda get-policy --function-name invite-landing --query Policy --output text 2>/dev/null || true)"
if [ -z "$policy" ] || [ "$policy" = "None" ] || ! printf '%s' "$policy" | jq -e '
      [.Statement[] | select(.Effect=="Allow")
        | select((.Action | if type=="array" then . else [.] end) | index("lambda:InvokeFunctionUrl"))
        | select(.Principal == "*" or .Principal.AWS == "*")] | length > 0' >/dev/null 2>&1; then
  echo "AuthType is NONE, but the function's resource policy has no statement letting everyone (principal *) use lambda:InvokeFunctionUrl. On AWS that still returns 403 Forbidden."
  exit 1
fi

origins="$(printf '%s' "$cfg" | jq -c '.Cors.AllowOrigins // []')"
if [ "$origins" != '["https://pebblestudio.example"]' ]; then
  echo "CORS AllowOrigins is $origins. The URL must keep allowing only the sign-up page (https://pebblestudio.example); an edit or a delete-and-recreate lost the original CORS settings."
  exit 1
fi

admin_auth="$(aws_local lambda get-function-url-config --function-name invite-admin --query AuthType --output text 2>/dev/null || true)"
if [ "$admin_auth" != "AWS_IAM" ]; then
  echo "invite-admin's URL is now '$admin_auth'. The internal function must stay IAM-protected."
  exit 1
fi

# Behaviour: act like the visitor's browser, with no AWS credentials.
host="$(printf '%s' "$cfg" | jq -r '.FunctionUrl' | sed -e 's#^[a-z]*://##' -e 's#/$##')"
code="$(curl -s -o /tmp/pebble-$$.out -w '%{http_code}' -X POST -H "Host: $host" -H 'content-type: application/json' \
  -d '{"email":"ada@pebblestudio.example"}' "$AWS_ENDPOINT_URL/signup" || true)"
body="$(cat /tmp/pebble-$$.out 2>/dev/null || true)"; rm -f /tmp/pebble-$$.out
if [ "$code" != "201" ]; then
  echo "An anonymous sign-up request returned HTTP $code instead of 201: $body"
  exit 1
fi
if [ "$(printf '%s' "$body" | jq -r '.invited // empty')" != "ada@pebblestudio.example" ]; then
  echo "The endpoint answered 201 but with an unexpected body: $body"
  exit 1
fi

echo "The sign-up page can now post invitations anonymously, from its own origin only; invite-admin is still private."
