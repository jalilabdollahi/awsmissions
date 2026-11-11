#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SM="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:kestrel-manifest-import"
accepted_q="$AWS_ENDPOINT_URL/${ACCOUNT_ID}/kestrel-accepted"
quarantine_q="$AWS_ENDPOINT_URL/${ACCOUNT_ID}/kestrel-quarantine"
aws_local sqs purge-queue --queue-url "$accepted_q" >/dev/null 2>&1 || true
aws_local sqs purge-queue --queue-url "$quarantine_q" >/dev/null 2>&1 || true

batch="B-$(date +%s)"
manifest="{\"batchId\":\"$batch\",\"parcels\":[
 {\"id\":\"P1\",\"weightKg\":2.5,\"zip\":\"10115\"},
 {\"id\":\"P2\",\"weightKg\":0,\"zip\":\"20095\"},
 {\"id\":\"P3\",\"weightKg\":11,\"zip\":\"80331\"},
 {\"id\":\"P4\",\"weightKg\":0.4,\"zip\":\"50667\"}]}"

ex="$(aws_local stepfunctions start-execution --state-machine-arn "$SM" --input "$manifest" --query executionArn --output text)"
over() { [ "$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)" != "RUNNING" ]; }
wait_for "the manifest import" 50 over || { echo "The import is still running after 50s."; exit 1; }

status="$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)"
if [ "$status" != "SUCCEEDED" ]; then
  echo "The import ended as $status: $(aws_local stepfunctions describe-execution --execution-arn "$ex" --query '[error,cause]' --output text | cut -c1-260)"
  exit 1
fi

drain() { # queue url -> bodies, one per line
  aws_local sqs receive-message --queue-url "$1" --max-number-of-messages 10 --wait-time-seconds 2 \
    --visibility-timeout 0 --query 'Messages[].Body' --output text | tr '\t' '\n'
}
accepted="$(drain "$accepted_q")"
quarantined="$(drain "$quarantine_q")"

python3 - "$batch" "$accepted" "$quarantined" <<'PY'
import json, sys

batch, accepted_raw, quarantined_raw = sys.argv[1:4]

def docs(raw):
    out = []
    for line in raw.splitlines():
        line = line.strip()
        if line:
            try:
                out.append(json.loads(line))
            except ValueError:
                out.append({"_raw": line})
    return out

def text(doc):
    return json.dumps(doc)

accepted, quarantined = docs(accepted_raw), docs(quarantined_raw)
problems = []

ids = sorted(d.get("parcelId", "?") for d in accepted if d.get("batchId") == batch)
if ids != ["P1", "P3", "P4"]:
    problems.append("kestrel-accepted should hold P1, P3 and P4 tagged with batchId %s, found: %s" % (batch, ids or "nothing"))
if any("P2" in text(d) for d in accepted):
    problems.append("the malformed parcel P2 was accepted")
hit = [d for d in quarantined if "P2" in text(d)]
if len(hit) != 1:
    problems.append("kestrel-quarantine should hold exactly one message about P2, found %d" % len(hit))
else:
    body = text(hit[0])
    if batch not in body:
        problems.append("the quarantine message for P2 does not mention its batchId")
    if "MalformedParcel" not in body and "impossible weight" not in body:
        problems.append("the quarantine message for P2 does not say why it was rejected")
if len(quarantined) != 1:
    problems.append("kestrel-quarantine holds %d messages, expected 1 (only P2)" % len(quarantined))

if problems:
    print("The manifest was processed, but:")
    for p in problems:
        print(" - " + p)
    sys.exit(1)
PY

echo "Three parcels accepted with their batchId, the malformed one quarantined with its reason, and the import still succeeded."
