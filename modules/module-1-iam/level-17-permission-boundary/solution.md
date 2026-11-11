# Solution

With a permissions boundary, the user's effective permissions are the **intersection** of the identity policy and the boundary. The identity policy allows `s3:*` everywhere, but the boundary only allows `ListBucket` and `GetObject` on the sandbox buckets, so `PutObject` is not in the intersection.

1. Inspect the boundary:

```bash
aws iam get-user --user-name skyhook-intern --query User.PermissionsBoundary
aws iam get-policy-version --policy-arn arn:aws:iam::000000000000:policy/intern-boundary --version-id v1
```

2. In `boundary.json` (`edit`) add `s3:PutObject` to the allowed actions. Keep the Resource limited to the `skyhook-sandbox-*` buckets.
3. A managed policy is changed by publishing a new default version:

```bash
aws iam create-policy-version \
  --policy-arn arn:aws:iam::000000000000:policy/intern-boundary \
  --policy-document file://boundary.json \
  --set-as-default
```

Detaching the boundary or widening it to `"Resource": "*"` would let uploads through and also open `skyhook-prod-telemetry`, because the identity policy is `s3:*` on everything. `check` verifies the intern still cannot touch production.
