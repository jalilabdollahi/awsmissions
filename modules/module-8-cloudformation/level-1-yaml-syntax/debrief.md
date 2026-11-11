# Debrief: CloudFormation reads YAML first, AWS second

A template goes through two very different gates:

1. **Parsing.** The service must be able to read the document as YAML or JSON. Failure here is a synchronous `ValidationError` ("Template format error") and no stack is created, so there is nothing to roll back and nothing in the events list.
2. **Semantic validation and provisioning.** Only now does CloudFormation look at resource types, properties and references. Failures here produce a stack with `CREATE_FAILED` events.

That is why Priya's deploy printed an error but `describe-stack-events` had nothing to show: the stack never existed.

**Why indentation bites.** YAML has no braces to anchor nesting. One stray space turns a sibling into a malformed child. Tabs are not allowed for indentation at all.

**In real life**
- `aws cloudformation validate-template --template-body file://template.yaml` checks structure before you deploy. In real AWS it also catches unknown resource types and malformed intrinsic functions.
- Run `cfn-lint` in your editor or pre-commit hook; it reports the same line and column plus many semantic problems the parser alone cannot see.
- Prefer a formatter or an editor with visible whitespace for YAML, and keep indentation to two spaces everywhere so mistakes stand out.
