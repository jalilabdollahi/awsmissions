#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name clinic-appointments \
  --attribute-definitions AttributeName=patientId,AttributeType=S AttributeName=apptDate,AttributeType=S \
  --key-schema AttributeName=patientId,KeyType=HASH AttributeName=apptDate,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST >/dev/null

put() {
  aws_local dynamodb put-item --table-name clinic-appointments --item "$1"
}
put '{"patientId":{"S":"p-4410"},"apptDate":{"S":"2026-05-02"},"severity":{"N":"2"},"reason":{"S":"annual checkup"},"clinic":{"S":"north"}}'
put '{"patientId":{"S":"p-4410"},"apptDate":{"S":"2026-05-09"},"severity":{"N":"5"},"reason":{"S":"chest pain follow-up"},"clinic":{"S":"north"}}'
put '{"patientId":{"S":"p-4410"},"apptDate":{"S":"2026-06-14"},"severity":{"N":"1"},"reason":{"S":"vaccination"},"clinic":{"S":"east"}}'
put '{"patientId":{"S":"p-9020"},"apptDate":{"S":"2026-05-20"},"severity":{"N":"3"},"reason":{"S":"x-ray review"},"clinic":{"S":"north"}}'

echo "clinic-appointments holds 4 bookings. severity-index is nowhere to be found."
