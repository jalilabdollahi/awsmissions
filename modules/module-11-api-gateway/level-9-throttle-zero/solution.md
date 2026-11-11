# Solution

Throttling is stored in the stage's method settings. `*/*` is the default for every method; `~1checkout/POST` is the override for `POST /checkout` (a `/` in a path is escaped as `~1`).

```bash
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='ticketdash-api'].id | [0]" --output text)

aws apigateway update-stage --rest-api-id $API_ID --stage-name v2 --patch-operations \
  'op=replace,path=/*/*/throttling/rateLimit,value=200' \
  'op=replace,path=/*/*/throttling/burstLimit,value=400' \
  'op=replace,path=/~1checkout/POST/throttling/rateLimit,value=15' \
  'op=replace,path=/~1checkout/POST/throttling/burstLimit,value=30'

aws apigateway get-stage --rest-api-id $API_ID --stage-name v2 --query methodSettings
```
