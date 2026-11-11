# INC-4417 - Partner catalogue API returns errors since the migration

Quillmark Press (book distributor). The catalogue API is consumed by three
retail partners and our own mobile app.

## Timeline from the status channel
- 14:02  Platform finished migrating the catalogue API from the old account
  layout to a new REST API called `qm-catalog` (Terraform was "mostly
  applied", the rest was clicked through in the console).
- 14:20  Partner "Paperfox" reports 403s, "BookBarn" reports 404 "Stage not
  found", the mobile app reports 5xx / timeouts. Different people see
  different errors, which is the first clue that more than one thing is wrong.

## Contract with partners (do not change)
- Base path: `https://<api-host>/prod/books`  (stage name is `prod`)
- Every call carries an `x-api-key` header. Partner keys are managed through
  the usage plan; calls without a key must still be rejected.
- Response: JSON `{"books": [...]}` produced by Lambda `qm-catalog-api`.

## Things we think we know
- The API key `qm-partner-key` was created and attached to a usage plan.
- The Lambda function was renamed during the migration (it used to be
  `qm-catalog-api-v1`).
- Someone parked the function at zero concurrency while testing a rollback and
  may not have undone it.

## Test it like a partner
    curl -H "x-api-key: <value>" "$AWS_ENDPOINT_URL/restapis/<api-id>/prod/_user_request_/books"
