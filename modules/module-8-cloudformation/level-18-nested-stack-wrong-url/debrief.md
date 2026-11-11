# Debrief: nested stacks are an interface, and every layer of it can be wrong

A nested stack is a normal resource, `AWS::CloudFormation::Stack`, whose properties are the child's contract:

| Parent property | Must match, in the child |
|---|---|
| `TemplateURL` | an existing S3 object CloudFormation can read |
| `Parameters` | declared `Parameters` (and all required ones supplied) |
| `!GetAtt Child.Outputs.X` | a declared `Outputs` key |

Three separate layers, three separate failure styles in this mission: a loud failure on the URL, a loud failure on the parameter, and a *quiet* one on the output, where a lenient engine just substitutes the literal text of your reference. Real CloudFormation rejects the unknown output name at deploy time. Always test the thing the output is *for*, not only that the stack went green.

**Why nest at all**
- Reuse a vetted building block (alerting, a VPC, a standard bucket) across stacks.
- Break a template out of the 500-resource and 1 MB limits.
- Deploy a whole tree with one command; rollbacks and deletes cascade.

**Practicalities**
- `aws cloudformation package` (or `sam package`) uploads local child templates to S3 and rewrites `TemplateURL` for you, which removes the whole "wrong URL" class of bugs.
- Version the child templates in S3 (versioned bucket, version IDs in the URL) so a parent cannot silently pick up a breaking change.
- Updates to a child must go through the parent. Updating the child stack directly causes drift between parent and child.
- Debug bottom-up: the child stack has its own events under its own name, usually `<parent>-<LogicalId>-<random>`.
