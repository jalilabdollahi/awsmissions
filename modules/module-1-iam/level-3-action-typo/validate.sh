#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp)"
trap 'rm -f "$work"' EXIT

as_worker() { aws_as_user lantern-thumbs "$@"; }

# Step 1 of the worker's job: fetch an original.
if ! out="$(as_worker s3api get-object --bucket lantern-originals --key 2025/10/portrait-0042.jpg "$work" 2>&1)"; then
  echo "Fetching an original as lantern-thumbs fails: $(printf '%s' "$out" | tail -1)"
  echo "IAM only matches action names it knows. Check each Action in the policy character by character."
  FAILED=1
fi

# Step 2: store the thumbnail.
echo "thumb $(date +%s)" > "$work"
if ! out="$(as_worker s3api put-object --bucket lantern-thumbnails --key 2025/10/portrait-0042.jpg --body "$work" 2>&1)"; then
  echo "Writing a thumbnail as lantern-thumbs fails: $(printf '%s' "$out" | tail -1)"
  FAILED=1
fi
if [ "${FAILED:-0}" = 1 ]; then exit 1; fi

# The fix must not widen the blast radius.
if as_worker s3api put-object --bucket lantern-originals --key 2025/10/overwrite.jpg --body "$work" >/dev/null 2>&1; then
  echo "The worker can now write into lantern-originals. It must only write to the thumbnails bucket."
  exit 1
fi
if as_worker s3api delete-object --bucket lantern-thumbnails --key 2025/10/portrait-0001.jpg >/dev/null 2>&1; then
  echo "The worker can delete thumbnails. Grant only the two actions the job needs."
  exit 1
fi
if as_worker s3api get-object --bucket lantern-thumbnails --key 2025/10/portrait-0001.jpg "$work" >/dev/null 2>&1; then
  echo "The worker can read the thumbnails bucket too. Reading is only needed on originals."
  exit 1
fi

echo "lantern-thumbs reads originals, writes thumbnails, and nothing else. Resize queue is moving."
