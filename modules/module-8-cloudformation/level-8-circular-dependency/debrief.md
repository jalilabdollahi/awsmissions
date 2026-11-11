# Debrief: dependency graphs and how to break a cycle

CloudFormation turns your template into a directed graph before it creates anything. Edges come from:

- `DependsOn` (explicit),
- `Ref`, `Fn::GetAtt` and `Fn::Sub` with `${Resource}` or `${Resource.Attr}` (implicit).

If the graph has a cycle there is no valid creation order, so the template is rejected up front. The error lists the resources in the loop, and the fix is always to remove one edge.

**This particular loop is a classic.** S3 validates that the topic accepts its notifications when the bucket's `NotificationConfiguration` is applied, so the topic policy must exist first (`DependsOn`). A well-written policy also limits publishers to one bucket with `aws:SourceArn`, which tempts you to `GetAtt` the bucket's ARN. Together: a cycle.

**Ways out**
1. Construct the name-based ARN yourself (`arn:aws:s3:::my-bucket`, or `!Sub "arn:aws:s3:::${BucketNameParameter}"`). Works whenever the name is not auto-generated.
2. Make the name a parameter used by both resources, which also removes duplication.
3. Create the notification in a second step (a second stack, or an `AWS::S3::BucketNotification`-style custom resource) once both resources exist.

**What not to do.** Dropping the `aws:SourceArn` condition makes the template deployable but lets any bucket in any account publish to your topic: the confused-deputy problem. Always keep the condition.

**In real life** the same shape appears with security groups that reference each other (use separate ingress rule resources), and with Lambda permission plus event source wiring.
