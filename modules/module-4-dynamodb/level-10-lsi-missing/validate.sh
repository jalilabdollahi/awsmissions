#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

T=clinic-appointments
if ! aws_local dynamodb describe-table --table-name "$T" >/dev/null 2>&1; then
  echo "$T does not exist right now. It has to be back under the same name."
  exit 1
fi

bykey="$(aws_local dynamodb query --table-name "$T" --index-name severity-index \
  --key-condition-expression 'patientId = :p' --expression-attribute-values '{":p":{"S":"p-4410"}}' \
  --no-scan-index-forward --query 'Items[].reason.S' --output text 2>&1)" || {
  echo "Querying severity-index fails: $(printf '%s' "$bykey" | tail -1)"
  exit 1
}
if [ "$bykey" != "$(printf 'chest pain follow-up\tannual checkup\tvaccination')" ]; then
  echo "severity-index for p-4410, most urgent first, returned [$bykey]."
  echo "Expected: chest pain follow-up, annual checkup, vaccination (severity 5, 2, 1) with the reason attribute present."
  exit 1
fi

n="$(aws_local dynamodb scan --table-name "$T" --select COUNT --query Count --output text)"
if [ "$n" != "4" ]; then
  echo "Expected all 4 appointments to be present, found $n."
  exit 1
fi

row="$(aws_local dynamodb get-item --table-name "$T" \
  --key '{"patientId":{"S":"p-9020"},"apptDate":{"S":"2026-05-20"}}' \
  --query 'Item.[severity.N,reason.S,clinic.S]' --output text)"
if [ "$row" != "$(printf '3\tx-ray review\tnorth')" ]; then
  echo "Appointment p-9020 / 2026-05-20 lost or changed attributes (got [$row]). Every attribute has to be migrated."
  exit 1
fi

# The index must be maintained for new writes too.
aws_local dynamodb put-item --table-name "$T" \
  --item '{"patientId":{"S":"p-4410"},"apptDate":{"S":"2026-07-01"},"severity":{"N":"9"},"reason":{"S":"validator probe"}}' >/dev/null
top="$(aws_local dynamodb query --table-name "$T" --index-name severity-index \
  --key-condition-expression 'patientId = :p' --expression-attribute-values '{":p":{"S":"p-4410"}}' \
  --no-scan-index-forward --limit 1 --query 'Items[0].reason.S' --output text)"
aws_local dynamodb delete-item --table-name "$T" --key '{"patientId":{"S":"p-4410"},"apptDate":{"S":"2026-07-01"}}' >/dev/null
if [ "$top" != "validator probe" ]; then
  echo "A newly written appointment is not visible through severity-index (top result: $top)."
  exit 1
fi
echo "severity-index works and all four appointments made the trip."
