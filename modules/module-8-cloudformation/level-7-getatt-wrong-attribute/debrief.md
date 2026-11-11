# Debrief: GetAtt is a lookup in a fixed table

`Ref` returns one default value per resource type. `Fn::GetAtt` reaches for everything else, but only attributes the resource provider publishes. The names are not consistent between services, which is why guessing goes wrong:

| Resource | ARN attribute |
|---|---|
| `AWS::S3::Bucket` | `Arn` |
| `AWS::SQS::Queue` | `Arn` (the `Ref` is the URL) |
| `AWS::Lambda::Function` | `Arn` |
| `AWS::DynamoDB::Table` | `Arn` (and `StreamArn`) |
| `AWS::SNS::Topic` | `Ref` is the ARN; `TopicName` is an attribute |

**Failed updates are safe, if noisy.** The update touched the bucket and the role in parallel. When the role failed, CloudFormation deleted the archive bucket it had just created and left the stack on release 1. That is `UPDATE_ROLLBACK_COMPLETE`, a healthy, updatable state, unlike `ROLLBACK_COMPLETE` after a failed *create*.

**Why the refusal is good news.** Policies built from unresolved text would be accepted by IAM and match nothing, so the bot would fail with `AccessDenied` weeks later with no obvious cause. Failing at deploy time is much cheaper.

**In real life**
- Look up the attribute list on the resource's documentation page ("Return values > Fn::GetAtt") before using it.
- `cfn-lint` validates attribute names per type (`E1010`).
- Use change sets (`create-change-set`, `describe-change-set`) to preview a release before executing it.
