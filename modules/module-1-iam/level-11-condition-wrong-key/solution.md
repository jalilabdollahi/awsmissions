# Solution

`aws:Region` is not an IAM global condition key. The region a request is aimed at is exposed as `aws:RequestedRegion`. IAM treats an unknown key as "absent", so a `StringEquals` on it never matches and the Allow statement never applies.

1. In `policy.json` (`edit`) rename the key in the Condition:

```json
"Condition": { "StringEquals": { "aws:RequestedRegion": "eu-west-1" } }
```

2. Re-apply the policy:

```bash
aws iam put-user-policy --user-name meridian-eu-worker --policy-name eu-sqs-only --policy-document file://policy.json
```

3. `check` sends and receives on the EU queue and confirms the same user is refused in us-east-1.
