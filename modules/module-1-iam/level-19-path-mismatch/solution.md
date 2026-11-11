# Solution

An IAM user ARN includes the user's **path**: `arn:aws:iam::000000000000:user/contractors/redwood-kim`. The policy's Resource is `user/${aws:username}`, i.e. `user/redwood-kim`, which does not exist. In the pilot the test accounts had no path, which is why it worked there.

1. See the real ARN:

```bash
aws iam get-user --user-name redwood-kim --query User.Arn
```

2. Put the path into the Resource in `policy.json` (`edit`):

```json
"Resource": "arn:aws:iam::000000000000:user/contractors/${aws:username}"
```

3. Update the group's inline policy:

```bash
aws iam put-group-policy --group-name redwood-contractors --policy-name self-service-keys --policy-document file://policy.json
```

`user/*` or `user/contractors/*` would let every contractor look at every other contractor's keys. `check` tests that kim cannot reach lee or the staff account.
