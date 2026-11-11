#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://quill-manifest-offload >/dev/null
aws_local sqs create-queue --queue-name quill-manifest-jobs >/dev/null

# Build tonight's manifest (deterministic, about 1.3 MB) in the player's workspace.
mkdir -p "$WORKDIR/payload"
python3 - "$WORKDIR/payload/manifest.json" <<'PY'
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

echo "manifest.json is $(wc -c < "$WORKDIR/payload/manifest.json" | tr -d ' ') bytes. quill-manifest-jobs refuses to carry it."
