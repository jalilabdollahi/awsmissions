# Debrief: transforms and macros rewrite the template before it runs

A `Transform` section names one or more **macros**. CloudFormation passes the whole template through each macro and deploys the *output*. Two are built in:

- `AWS::Serverless-2016-10-31` (SAM): expands `AWS::Serverless::Function`, `Api`, `SimpleTable` and friends into plain resources, generating IAM roles, permissions and API Gateway wiring for you.
- `AWS::Include`: pulls a snippet of YAML from S3 into the template.
- `AWS::LanguageExtensions` adds `Fn::ForEach`, `Fn::Length`, `Fn::ToJsonString` and defaults for `FindInMap`.

You can also write your own macro as a Lambda function.

**Why the stack looked fine.** Real CloudFormation rejects a template with an unknown `AWS::Serverless::*` type outright. A lenient engine treats it as an opaque resource instead. The practical rule is the same: if you use SAM shorthand, the transform line is not optional.

**Practicalities**
- Stacks that use transforms need `CAPABILITY_AUTO_EXPAND` (and `CAPABILITY_IAM` when the expansion creates roles). `sam deploy` supplies them for you.
- In real AWS you can look at the expanded result with `aws cloudformation get-template --template-stage Processed`, which is the fastest way to debug a macro.
- Prefer `sam validate`/`sam build` locally; they catch a missing transform before any deploy.
- Transforms run on every update, so the generated resource names are stable only if your logical IDs are.
