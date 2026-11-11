# Debrief: row-level security with IAM

IAM normally decides "may this principal call this action on this table". DynamoDB adds **condition keys** that look inside the request:

- `dynamodb:LeadingKeys`: the partition key value(s) the request touches. Use it to give a tenant (or a mobile user via `${www.amazon.com:user_id}`/Cognito identity) access only to its own partition.
- `dynamodb:Attributes` and `dynamodb:Select`: which attributes can be read or written, and whether a request may return all attributes.
- `dynamodb:ReturnValues`, `dynamodb:ReturnConsumedCapacity`, `dynamodb:FirstPartitionKeyValues`.

Details that bite:
- Use `ForAllValues:StringEquals` with `LeadingKeys`. It is true when every partition key referenced is in your list, which is what you want for batch calls.
- The catch: `ForAllValues` is also true when the key is **absent from the request context**. `Scan` carries no leading keys, so with a leading-key condition a scan would be allowed and read everything. Never grant `Scan` alongside this pattern.
- Batch and transact operations evaluate the condition against all items in the request, so one foreign key denies the whole call.
- A partition key is a literal, so the tenant id belongs in the identity (an IAM user, a role session tag, a Cognito identity) and the policy must be generated per tenant (or use session tags: `"dynamodb:LeadingKeys": ["${aws:PrincipalTag/tenant}"]`).
- Separate tables per tenant remove the whole problem at the cost of operations; leading-key policies are the standard compromise (the SaaS Lens in the Well-Architected Framework discusses both).

The flaw was not in DynamoDB. The original policy answered "may it use the table" when the real question was "may it use these rows".
