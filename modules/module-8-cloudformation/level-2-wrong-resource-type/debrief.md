# Debrief: a resource type is a contract, and typos break it quietly

Every CloudFormation resource is identified by its `Type` string. The service looks that string up in a registry of resource providers; the provider knows which properties are valid and how to create, update and delete the real thing.

**What happens on a typo.** Real AWS rejects an unknown type during template validation with `Template format error: Unrecognized resource types`. This emulator is more lenient: it records the resource as "stubbed", marks the stack `CREATE_COMPLETE` and creates nothing. The lesson is the same either way, and the lenient behaviour is a good reminder that a green stack status only means "CloudFormation did everything you asked", not "everything you wanted exists".

**How to catch it early**
- `cfn-lint` flags unknown types instantly (error `E3001`).
- Look at `describe-stack-resources`, not just `describe-stacks`: the physical IDs tell you what was created.
- After any deploy, run one real smoke test (upload a file, publish a message). Healthy stack plus failing app is the signature of a missing resource.

**Fixing it in place.** Because the logical ID `ScannedForms` stayed the same, an `update-stack` swaps the stub for a real bucket. If you had also renamed the logical ID, CloudFormation would treat it as delete-old plus create-new, which matters for stateful resources.
