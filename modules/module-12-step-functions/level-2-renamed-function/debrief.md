# Debrief: the Resource ARN is a hard reference

A Task state's `Resource` is not a label, it is the address of what to run. Step Functions does not look the function up by "something similar", and it does not know a function was renamed. If the ARN no longer resolves, the Task fails immediately with `Lambda.ResourceNotFoundException` ("Function not found") and nothing downstream runs.

Notice what the error is *not*: it is not an access error and not a code error. The execution history shows no `LambdaFunctionStarted` event because the function was never reached.

**Why this keeps happening.** Names are copied into definitions by hand or from a template, while functions are renamed, moved between accounts or regions, or get new aliases. Anything that references an ARN as a literal string breaks silently on rename.

**In real life**
- Keep ARNs out of hand-written JSON: with CloudFormation/CDK/Terraform use `DefinitionSubstitutions` (`${CheckFunctionArn}`) so the template stays in sync with the resource.
- Point at an alias (`function:name:live`) rather than `$LATEST`, so a deploy changes the alias and not the workflow.
- A wildcard IAM resource such as `refill-eligibility-check*` also matches the `-staging` function. If your naming scheme allows that, your workflow can quietly call the wrong environment. Check outputs, not just success.
