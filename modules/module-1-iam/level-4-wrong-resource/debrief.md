# Debrief: an ARN is an exact address

`Resource` entries are matched against the ARN of the thing being called. For SQS that ARN carries four pieces of information that all have to match: service (`sqs`), **region**, **account ID** and queue name. The policy that was copied from staging had the right queue names but a different region and a different account, so it described queues that do not exist in this account. IAM does not warn about that; the statement just never applies.

**In real life**
- Never hand-type ARNs. Read them from the service (`QueueArn`, `get-role`, `describe-*`) or build them from variables in your IaC tool.
- Regions and accounts differ between environments, so a policy "promoted" from staging is a classic source of this bug. Parameterise them.
- Wildcards inside an ARN can help (`arn:aws:sqs:*:*:orders-*`) but they also match queues you did not intend. Be as specific as the use case allows.
- A `Deny` or `Allow` statement on the wrong ARN fails silently in both directions, so test the allowed and the forbidden call.
