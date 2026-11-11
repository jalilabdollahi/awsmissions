# Solution

The user has no permissions of her own and belongs to no group, so nothing allows anything. The account already has the groups; she just needs to be in the right one.

1. See which groups exist and what they grant:

```bash
aws iam list-groups
aws iam list-group-policies --group-name nimbus-analysts
aws iam get-group-policy --group-name nimbus-analysts --policy-name curated-read
aws iam list-attached-group-policies --group-name nimbus-platform-admins
```

2. `nimbus-analysts` allows reading the curated bucket and nothing else. Add her:

```bash
aws iam add-user-to-group --group-name nimbus-analysts --user-name nimbus-priya
```

Picking `nimbus-platform-admins` would also "work", but it grants administrator access, and `nimbus-contractors` only reads the raw bucket. `check` tests both directions.
