#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=ml-case-documents
bad=0
echo "INC-6611 recovery check"

if ! aws_local s3api head-bucket --bucket "$B" >/dev/null 2>&1; then echo "The bucket $B is gone."; exit 1; fi
if ! aws_local dynamodb describe-table --table-name ml-case-index >/dev/null 2>&1; then echo "The live table ml-case-index is gone; the cases have to be back in it."; exit 1; fi

# 1. Documents: right content.
docs_bad=0
check_doc() { # key expected-prefix
  body="$(aws_local s3api get-object --bucket "$B" --key "$1" /dev/stdout 2>/dev/null | head -c 200 || true)"
  case "$body" in
    "$2"*) ;;
    *) echo "          - $1: ${body:-not readable}" | cut -c1-110; docs_bad=$((docs_bad + 1)) ;;
  esac
}
check_doc contracts/acme-msa.txt "MSA between Marlow & Quayle and Acme"
check_doc contracts/brightwater-nda.txt "NDA with Brightwater"
check_doc pleadings/calder-v-dunmore.txt "Calder v Dunmore"
if [ "$docs_bad" -eq 0 ]; then
  echo "[ok]    documents  all three documents are readable with their correct content"
else
  echo "[FAULT] documents  $docs_bad document(s) are missing or have the wrong content"
  bad=$((bad + 1))
fi

# 2. Case rows in the live table.
rows="$(aws_local dynamodb scan --table-name ml-case-index --output json | jq -r '[.Items[] | .caseId.S + ":" + .client.S] | sort | join(",")')"
if [ "$rows" = "C-101:Acme,C-102:Brightwater,C-103:Calder,C-104:Dunmore" ]; then
  echo "[ok]    cases      all four cases are in ml-case-index"
else
  echo "[FAULT] cases      ml-case-index holds: ${rows:-nothing}"
  bad=$((bad + 1))
fi

# 3. Versioning.
vs="$(aws_local s3api get-bucket-versioning --bucket "$B" --query Status --output text 2>/dev/null || true)"
if [ "$vs" = "Enabled" ]; then
  echo "[ok]    safety     bucket versioning is Enabled"
else
  echo "[FAULT] safety     bucket versioning is '${vs:-never enabled}'"
  bad=$((bad + 1))
fi

# 4. The intern: still useful, no longer dangerous.
stamp="$(date +%s)"
tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT; echo "scratch $stamp" > "$tmp"
aws_local s3 cp "$tmp" "s3://$B/scratch/read-$stamp.txt" >/dev/null
use_ok=1
aws_as_user ml-intern s3api get-object --bucket "$B" --key "scratch/read-$stamp.txt" /dev/null >/dev/null 2>&1 || use_ok=0
aws_as_user ml-intern s3api put-object --bucket "$B" --key "intake/note-$stamp.txt" --body "$tmp" >/dev/null 2>&1 || use_ok=0
aws_as_user ml-intern dynamodb put-item --table-name ml-case-index --item "{\"caseId\":{\"S\":\"scratch2-$stamp\"},\"client\":{\"S\":\"probe\"}}" >/dev/null 2>&1 || use_ok=0
aws_as_user ml-intern dynamodb scan --table-name ml-case-index --max-items 1 >/dev/null 2>&1 || use_ok=0
aws_local dynamodb delete-item --table-name ml-case-index --key "{\"caseId\":{\"S\":\"scratch2-$stamp\"}}" >/dev/null 2>&1 || true
aws_local s3 rm "s3://$B/intake/note-$stamp.txt" >/dev/null 2>&1 || true
aws_local s3 rm "s3://$B/scratch/read-$stamp.txt" >/dev/null 2>&1 || true
if [ "$use_ok" -eq 0 ]; then
  echo "BLOCKER: the intern can no longer read objects or add data. Casework has to continue; remove only the destructive actions."
  exit 1
fi
aws_local s3 cp "$tmp" "s3://$B/scratch/probe-$stamp.txt" >/dev/null
VID="$(aws_local s3api list-object-versions --bucket "$B" --prefix "scratch/probe-$stamp.txt" --query 'Versions[0].VersionId' --output text 2>/dev/null || echo null)"
aws_local dynamodb put-item --table-name ml-case-index --item "{\"caseId\":{\"S\":\"scratch-$stamp\"},\"client\":{\"S\":\"probe\"}}" >/dev/null
deny_ok=1
if aws_as_user ml-intern s3api delete-object --bucket "$B" --key "scratch/probe-$stamp.txt" >/dev/null 2>&1; then deny_ok=0; fi
if [ "$VID" != "null" ] && [ "$VID" != "None" ] && aws_as_user ml-intern s3api delete-object --bucket "$B" --key "scratch/probe-$stamp.txt" --version-id "$VID" >/dev/null 2>&1; then deny_ok=0; fi
if aws_as_user ml-intern dynamodb delete-item --table-name ml-case-index --key "{\"caseId\":{\"S\":\"scratch-$stamp\"}}" >/dev/null 2>&1; then deny_ok=0; fi
aws_local dynamodb delete-item --table-name ml-case-index --key "{\"caseId\":{\"S\":\"scratch-$stamp\"}}" >/dev/null 2>&1 || true
aws_local s3 rm "s3://$B/scratch/probe-$stamp.txt" >/dev/null 2>&1 || true
if [ "$deny_ok" -eq 1 ]; then
  echo "[ok]    guardrail  the intern cannot delete objects, object versions or table items"
else
  echo "[FAULT] guardrail  the intern can still delete data"
  bad=$((bad + 1))
fi

if [ "$bad" -gt 0 ]; then
  echo "$bad item(s) still open."
  exit 1
fi
echo "Documents and cases are back, versioning is on again and the intern cannot delete anything. Marlow & Quayle can open Monday."
