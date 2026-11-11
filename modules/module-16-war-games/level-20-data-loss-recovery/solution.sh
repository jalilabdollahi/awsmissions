#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=ml-case-documents

# 1. Re-enable versioning, then recover the documents: remove each delete marker; for the corrupted
#    contract, copy its last good version over the bad one.
aws_local s3api put-bucket-versioning --bucket "$B" --versioning-configuration Status=Enabled
aws_local s3api list-object-versions --bucket "$B" --output json > versions.json
python3 - <<'PY'
import json, subprocess, os
ep = os.environ["AWS_ENDPOINT_URL"]
def aws(*a):
    return subprocess.run(["aws", "--endpoint-url", ep, *a], check=True, capture_output=True, text=True).stdout
doc = json.load(open("versions.json"))
for m in doc.get("DeleteMarkers", []):
    if m["IsLatest"]:
        aws("s3api", "delete-object", "--bucket", "ml-case-documents", "--key", m["Key"], "--version-id", m["VersionId"])
good = [v for v in doc["Versions"] if v["Key"] == "contracts/acme-msa.txt" and v["Size"] > 20]
good.sort(key=lambda v: v["LastModified"])
aws("s3api", "copy-object", "--bucket", "ml-case-documents", "--key", "contracts/acme-msa.txt",
    "--copy-source", "ml-case-documents/contracts/acme-msa.txt?versionId=" + good[-1]["VersionId"])
PY

# 2. Restore the table to the last good time into a new table, then copy the cases back into the live table.
LAST="$(aws_local ssm get-parameter --name /marlow/incident/last-good-time --query Parameter.Value --output text)"
aws_local dynamodb restore-table-to-point-in-time --source-table-name ml-case-index \
  --target-table-name ml-case-index-restored --restore-date-time "$LAST" >/dev/null
ready() { [ "$(aws_local dynamodb describe-table --table-name ml-case-index-restored --query Table.TableStatus --output text)" = "ACTIVE" ]; }
wait_for "restored table" 60 ready
aws_local dynamodb scan --table-name ml-case-index-restored --output json > restored.json
python3 - <<'PY'
import json, subprocess, os
ep = os.environ["AWS_ENDPOINT_URL"]
for item in json.load(open("restored.json"))["Items"]:
    subprocess.run(["aws", "--endpoint-url", ep, "dynamodb", "put-item", "--table-name", "ml-case-index",
                    "--item", json.dumps(item)], check=True, stdout=subprocess.DEVNULL)
PY

# 3. The intern keeps reading and adding, but loses every delete.
aws_local iam put-user-policy --user-name ml-intern --policy-name casework --policy-document '{
  "Version":"2012-10-17","Statement":[
   {"Effect":"Allow","Action":["s3:GetObject","s3:PutObject","s3:ListBucket"],"Resource":["arn:aws:s3:::ml-case-documents","arn:aws:s3:::ml-case-documents/*"]},
   {"Effect":"Allow","Action":["dynamodb:GetItem","dynamodb:PutItem","dynamodb:Query","dynamodb:Scan"],"Resource":"arn:aws:dynamodb:us-east-1:000000000000:table/ml-case-index"}]}'
