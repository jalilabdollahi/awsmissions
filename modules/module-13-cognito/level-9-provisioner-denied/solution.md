# Solution

Two things are wrong with the inline policy `onboarding`:

1. Its `Resource` names a pool id that no longer exists (the pre-migration pool). The rebuilt pool has a new id, and Cognito ARNs contain it.
2. It only lists `AdminCreateUser` and `AdminGetUser`. Setting the password and joining the group need `AdminSetUserPassword` and `AdminAddUserToGroup`.

1. Read the policy and find the real pool:

```bash
aws iam get-user-policy --user-name fernwood-provisioner --policy-name onboarding
aws cognito-idp list-user-pools --max-results 10
```

2. Write a policy with the four actions, scoped to the ARN of `fernwood-staff` (`arn:aws:cognito-idp:<region>:<account>:userpool/<pool-id>`):

```bash
aws iam put-user-policy --user-name fernwood-provisioner --policy-name onboarding \
  --policy-document file://policy.json
```

with a statement like:

```json
{
  "Effect": "Allow",
  "Action": [
    "cognito-idp:AdminCreateUser",
    "cognito-idp:AdminGetUser",
    "cognito-idp:AdminSetUserPassword",
    "cognito-idp:AdminAddUserToGroup"
  ],
  "Resource": "arn:aws:cognito-idp:us-east-1:000000000000:userpool/<fernwood-staff pool id>"
}
```

3. Run `check`. The validator acts as `fernwood-provisioner`: it must be able to onboard a person in the staff pool, and it must be refused when it tries to delete a user or to touch the contractors pool.
