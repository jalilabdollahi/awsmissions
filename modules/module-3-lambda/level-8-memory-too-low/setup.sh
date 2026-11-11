#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

cat > "$workdir/trust.json" <<'JSON'
{"Version": "2012-10-17",
 "Statement": [{"Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}
JSON
aws_local iam create-role --role-name tile-stitcher-role \
  --assume-role-policy-document "file://$workdir/trust.json" >/dev/null

cp "$MISSION_DIR/workspace/stitch.mjs" "$workdir/"
zip -qj "$workdir/package.zip" "$workdir/stitch.mjs"

jq -n --arg role "arn:aws:iam::${ACCOUNT_ID}:role/tile-stitcher-role" '{
  FunctionName: "tile-stitcher",
  Runtime: "nodejs20.x",
  Handler: "stitch.handler",
  Role: $role,
  MemorySize: 128,
  Timeout: 20
}' > "$workdir/function.json"
aws_local lambda create-function --cli-input-json "file://$workdir/function.json" \
  --zip-file "fileb://$workdir/package.zip" >/dev/null

echo "tile-stitcher is deployed with 128 MB of memory."
