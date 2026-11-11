#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

run="$(date +%s)"
prod_pdf="inbox/INV-$run.pdf"
prod_txt="inbox/NOTE-$run.txt"
stg_pdf="inbox/INV-$run.pdf"

in_ledger() {
  aws_local dynamodb get-item --table-name marlowe-invoice-ledger \
    --key "{\"doc_id\":{\"S\":\"$1\"}}" --query 'Item.doc_id.S' --output text 2>/dev/null | grep -qx "$1"
}

echo '%PDF-1.4 prod' | aws_local s3 cp - "s3://marlowe-invoices-prod/$prod_pdf" >/dev/null
echo 'cover note' | aws_local s3 cp - "s3://marlowe-invoices-prod/$prod_txt" >/dev/null
echo '%PDF-1.4 staging' | aws_local s3 cp - "s3://marlowe-invoices-staging/$stg_pdf" >/dev/null

if ! wait_for "ledger entry for prod invoice" 20 in_ledger "marlowe-invoices-prod/$prod_pdf"; then
  echo "A PDF uploaded to marlowe-invoices-prod was not registered in the ledger within 20 seconds."
  exit 1
fi

sleep 4
if in_ledger "marlowe-invoices-staging/$stg_pdf"; then
  echo "A PDF from marlowe-invoices-staging was still registered in the real ledger. The staging bucket must stop triggering the function."
  exit 1
fi
if in_ledger "marlowe-invoices-prod/$prod_txt"; then
  echo "A .txt note in the prod bucket was registered as an invoice. Keep the .pdf suffix filter."
  exit 1
fi

echo "Prod PDFs are registered, staging is disconnected from the ledger, and non-PDFs are ignored."
