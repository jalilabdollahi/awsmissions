#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

HOST="driftwood-docs-site.s3-website-us-east-1.amazonaws.com"
fetch() { # path -> prints "status|body"
  curl -s -H "Host: $HOST" -w '|%{http_code}' "$AWS_ENDPOINT_URL$1"
}

root="$(fetch /)"
if ! printf '%s' "$root" | grep -q 'Driftwood Docs'; then
  echo "GET / on the website endpoint does not return the home page."
  exit 1
fi
guides="$(fetch /guides/)"
if ! printf '%s' "$guides" | grep -q '<h1>Guides</h1>'; then
  echo "GET /guides/ does not return guides/index.html. Folder requests need an index document."
  exit 1
fi
missing="$(fetch /no-such-page.html)"
if [ "${missing##*|}" != "404" ]; then
  echo "A missing page should answer with HTTP 404 (got ${missing##*|})."
  exit 1
fi
if printf '%s' "$missing" | grep -q 'Old error page'; then
  echo "Missing pages show the retired error.html. The site's current error page is the branded one."
  exit 1
fi
if ! printf '%s' "$missing" | grep -q 'Lost at sea'; then
  echo "A missing page does not show the site's own 404 page."
  exit 1
fi
echo "Root and folders serve their index pages, and missing pages show the branded 404."
