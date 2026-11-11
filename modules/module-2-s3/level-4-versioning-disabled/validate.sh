#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=ledgerly-contracts
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
key="validation/nda-$(date +%s).txt"
echo "revision one" > "$work/one.txt"
echo "revision two" > "$work/two.txt"

# Act like the contract service: upload the same key twice.
if ! aws_as_user contract-svc s3api put-object --bucket "$B" --key "$key" --body "$work/one.txt" >/dev/null 2>&1 ||
   ! aws_as_user contract-svc s3api put-object --bucket "$B" --key "$key" --body "$work/two.txt" >/dev/null 2>&1; then
  echo "contract-svc could not upload to the bucket at all; leave its permissions alone."
  exit 1
fi

versions="$(aws_as_user contract-svc s3api list-object-versions --bucket "$B" --prefix "$key" \
  --query 'Versions[].VersionId' --output text 2>/dev/null || true)"
count="$(printf '%s' "$versions" | wc -w | tr -d ' ')"
if [ "$count" -lt 2 ]; then
  echo "Two uploads to the same key left $count stored revision(s). The second upload still replaced the first."
  exit 1
fi

# The oldest revision must be downloadable by its version id.
oldest="$(aws_as_user contract-svc s3api list-object-versions --bucket "$B" --prefix "$key" \
  --query 'reverse(sort_by(Versions,&LastModified))[-1].VersionId' --output text)"
for vid in $versions; do
  if aws_as_user contract-svc s3api get-object --bucket "$B" --key "$key" --version-id "$vid" "$work/got.txt" >/dev/null 2>&1 \
     && grep -q "revision one" "$work/got.txt"; then
    echo "Both revisions are kept and the first one can still be downloaded by version id."
    exit 0
  fi
done
echo "Several versions are listed, but the first upload's content cannot be retrieved by version id (checked $oldest)."
exit 1
