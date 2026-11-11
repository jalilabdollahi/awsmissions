# Solution

Keep the table in the Resource, but add a condition on the partition key value of every request (`dynamodb:LeadingKeys`), and remove `dynamodb:Scan`, which cannot be constrained that way.

```json
{
  "Sid": "PortalContactsAccess",
  "Effect": "Allow",
  "Action": ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:Query"],
  "Resource": "arn:aws:dynamodb:us-east-1:000000000000:table/crmly-contacts",
  "Condition": {
    "ForAllValues:StringEquals": { "dynamodb:LeadingKeys": ["acme"] }
  }
}
```

```bash
aws iam put-user-policy --user-name portal-acme --policy-name portal-data-access --policy-document file://portal-policy.json
```

(`edit` opens `portal-policy.json`.)
