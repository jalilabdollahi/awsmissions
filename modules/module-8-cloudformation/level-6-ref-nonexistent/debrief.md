# Debrief: Ref resolves logical IDs, and a wrong one is easy to miss

`!Ref X` means one of three things, depending on what `X` is:

- a **parameter**: its value,
- a **pseudo parameter** such as `AWS::Region`: that value,
- a **resource** logical ID: the resource's "default" identifier (bucket name, queue URL, topic ARN, ...; the docs list it per type).

Real CloudFormation rejects a template when the name resolves to none of these (`Template format error: Unresolved resource dependencies [ManifestBuket] in the Resources block`). A tolerant emulator may instead just use the characters you typed. That is the dangerous variant of the same bug: no error, plausible output, wrong behaviour.

**Why Ref also creates ordering.** Every `Ref` and `GetAtt` is an implicit `DependsOn`, so CloudFormation creates the bucket before it creates the parameter that mentions it. A typo loses the dependency too.

**In real life**
- Publish values like bucket names through SSM parameters or stack outputs/exports from the template that owns them, never by hand, so consumers cannot drift from the real resource.
- `cfn-lint` flags unresolved references (`E1020`), so run it in CI.
- When something "works" but holds a strange value, read the stack's resolved parameters or outputs with `describe-stacks` and compare them with the physical IDs from `describe-stack-resources`.
