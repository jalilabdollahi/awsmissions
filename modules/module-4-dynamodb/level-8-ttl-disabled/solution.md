# Solution

TTL was enabled, but on an attribute called `expires`. The sessions store their expiry in `expiresAt`, so no item ever has the TTL attribute and nothing is ever deleted. Point TTL at the right attribute (disable first, then re-enable with the new name):

```bash
aws dynamodb describe-time-to-live --table-name loginly-sessions

aws dynamodb update-time-to-live --table-name loginly-sessions \
  --time-to-live-specification Enabled=false,AttributeName=expires
aws dynamodb update-time-to-live --table-name loginly-sessions \
  --time-to-live-specification Enabled=true,AttributeName=expiresAt
```

Deletion is performed in the background, so give it a short moment; the validator waits for it.
