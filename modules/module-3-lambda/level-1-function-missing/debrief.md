# Debrief: a function is code plus configuration

`ResourceNotFoundException: Function not found` is as plain as Lambda errors get: nothing is registered under that name in that account and Region. A Lambda function is only ever the sum of four things you must supply at creation time:

| Piece | Where it came from here |
|---|---|
| Deployment package | `zip` of `label_builder.py` |
| Runtime | `python3.12`, a supported one |
| Handler | `label_builder.build_label` = module file + function name |
| Execution role | the `parcel-label-role` that was already waiting |

The handler string is the part beginners trip on. It is not a file path and not the function name alone; Lambda imports the module named before the dot and calls the function named after it. If either is wrong the function exists but every invocation fails with `Runtime.HandlerNotFound` or `ImportModuleError` (the next mission explores that).

**Why it vanished:** infrastructure created by hand in a sandbox account is gone the moment the sandbox is. Roles often outlive the functions because they are managed by a different team or stack.

**In real life**
- Keep the function definition in code (CloudFormation, SAM, Terraform, CDK) so "recreate it" is a deploy, not an archaeology dig.
- `aws lambda list-functions` is the first thing to run when a caller reports "not found": the name, the Region and the account are all common culprits.
- Calling an alias or version that doesn't exist gives the same error, with `:alias` appended to the name.
