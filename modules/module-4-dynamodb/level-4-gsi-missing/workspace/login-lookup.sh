#!/usr/bin/env bash
# The login endpoint's lookup, as a shell one-liner. Usage: ./login-lookup.sh ines@example.org
aws --endpoint-url "${AWS_ENDPOINT_URL:-http://localhost:4566}" dynamodb query \
  --table-name cartwheel-members --index-name email-index \
  --key-condition-expression 'email = :e' \
  --expression-attribute-values "{\":e\":{\"S\":\"${1:?usage: login-lookup.sh EMAIL}\"}}" \
  --query 'Items[0].[email.S,memberId.S,plan.S]' --output text
