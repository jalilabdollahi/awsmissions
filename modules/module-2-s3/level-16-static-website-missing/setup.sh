#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
B=driftwood-docs-site

aws_local s3 mb "s3://$B" >/dev/null
echo '<html><body><h1>Driftwood Docs</h1></body></html>' > "$work/index.html"
echo '<html><body><h1>Guides</h1></body></html>' > "$work/guides.html"
echo '<html><body><h1>Lost at sea (404)</h1></body></html>' > "$work/404.html"
echo '<html><body><h1>Old error page</h1></body></html>' > "$work/error.html"
for pair in "index.html:index.html" "guides.html:guides/index.html" "404.html:404.html" "error.html:error.html"; do
  aws_local s3 cp "$work/${pair%%:*}" "s3://$B/${pair#*:}" --content-type text/html >/dev/null
done

echo "The website endpoint does not serve the docs site."
