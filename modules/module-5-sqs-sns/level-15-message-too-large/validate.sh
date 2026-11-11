#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

queue="$(aws_local sqs get-queue-url --queue-name quill-manifest-jobs --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$queue" ]; then
  echo "The queue quill-manifest-jobs is gone."
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# The manifest as the nightly job builds it (same generator as the workspace file).
python3 - "$work/expected.json" <<'PY'
import json, sys
rows = []
for n in range(3000):
    rows.append({
        "consignment": "QL-%06d" % n,
        "origin": ["Rotterdam", "Hamburg", "Antwerp", "Felixstowe"][n % 4],
        "destination": ["Singapore", "Busan", "Durban", "Santos"][n % 4],
        "tonnes": (n * 7) % 41 + 1,
        "hs_codes": ["8708.99", "8483.40", "7318.15"][: n % 3 + 1],
        "notes": "customs declaration line " + ("x" * 330),
    })
with open(sys.argv[1], "w") as fh:
    json.dump({"manifest_date": "2026-11-12", "consignments": rows}, fh)
PY
want="$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$work/expected.json")"

aws_local sqs receive-message --queue-url "$queue" --max-number-of-messages 10 --visibility-timeout 0 \
  --query 'Messages[].Body' --output json > "$work/messages.json" 2>/dev/null || echo '[]' > "$work/messages.json"

# Find a pointer message: a small JSON document naming a bucket and a key.
pointer="$(python3 - "$work/messages.json" <<'PY'
import json, sys
messages = json.load(open(sys.argv[1])) or []
def find(doc):
    if isinstance(doc, list):
        for item in doc:
            hit = find(item)
            if hit:
                return hit
    if isinstance(doc, dict):
        keys = {k.lower(): v for k, v in doc.items()}
        bucket = keys.get("bucket") or keys.get("s3bucketname") or keys.get("s3_bucket")
        key = keys.get("key") or keys.get("s3key") or keys.get("s3_key")
        if bucket and key:
            return "%s %s" % (bucket, key)
        for v in doc.values():
            hit = find(v)
            if hit:
                return hit
    return None
for body in messages:
    try:
        hit = find(json.loads(body))
    except ValueError:
        continue
    if hit:
        print(hit)
        break
PY
)"
if [ -z "$pointer" ]; then
  echo "No pointer message found in quill-manifest-jobs. The queue should hold a small JSON message naming the S3 bucket and key of the manifest."
  exit 1
fi
bucket="${pointer%% *}"
key="${pointer#* }"

if [ "$bucket" != "quill-manifest-offload" ]; then
  echo "The pointer names bucket '$bucket'. The manifest belongs in quill-manifest-offload."
  exit 1
fi
if ! aws_local s3api get-object --bucket "$bucket" --key "$key" "$work/fetched.json" >/dev/null 2>&1; then
  echo "The queue message points at s3://$bucket/$key, but that object does not exist."
  exit 1
fi
got="$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$work/fetched.json")"
if [ "$got" != "$want" ]; then
  echo "The object s3://$bucket/$key is not the unmodified manifest (checksum differs). The worker must get the exact document."
  exit 1
fi

too_big="$(python3 - "$work/messages.json" <<'PY'
import json, sys
print(any(len(b.encode()) >= 1024 for b in json.load(open(sys.argv[1])) or []))
PY
)"
if [ "$too_big" = "True" ]; then
  echo "The manifest is in S3, but the queue also holds a message of 1 KiB or more. Keep queue messages to the pointer only."
  exit 1
fi

echo "The worker can fetch the exact manifest from s3://$bucket/$key by following a small message in quill-manifest-jobs."
