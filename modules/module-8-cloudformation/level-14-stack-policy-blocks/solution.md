# Solution

`delete-stack` is refused with `cannot be deleted while TerminationProtection is enabled`. The deploy wrapper enables protection on every stack, including throwaway previews.

1. See which stacks are locked:

```bash
aws cloudformation describe-stacks --query 'Stacks[].[StackName,EnableTerminationProtection]'
```

2. Lift the lock on the merged PR's stack only, and delete it:

```bash
aws cloudformation update-termination-protection --stack-name kestrel-pr-731 --no-enable-termination-protection
aws cloudformation delete-stack --stack-name kestrel-pr-731
aws cloudformation wait stack-delete-complete --stack-name kestrel-pr-731
```

3. `check` confirms `kestrel-pr-731`, its bucket and its topic are gone, and that `kestrel-pr-742` and `kestrel-prod-core` still exist with protection enabled.
