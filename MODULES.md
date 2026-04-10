# AWSMissions — Module & Level Reference

> Full level-by-level breakdown for all 12 modules.
> Each level entry includes: folder name, display name, broken state, fix, XP, time.

---

## Module 1: IAM Foundations (20 Levels · Beginner · ~3,000 XP)

**Learning goal:** Master IAM policies, roles, trust relationships, and permission debugging.  
**Tools used:** `aws iam`, `aws sts`  
**LocalStack services:** IAM, STS

| # | Folder | Name | Broken State | Fix | XP | Time |
|---|--------|------|-------------|-----|----|------|
| 1 | `level-1-empty-policy` | The Empty Statement | Policy attached to role has `"Statement": []` — all actions denied | Add an `Allow` statement with the required action and resource | 100 | 5m |
| 2 | `level-2-deny-effect` | Wrong Side of the Law | Policy Effect is `"Deny"` instead of `"Allow"` on a basic S3 read policy | Change Effect to `"Allow"` | 100 | 5m |
| 3 | `level-3-action-typo` | The Misspelled Gate | Policy action has typo: `"s3:GetObjcet"` — IAM rejects all GetObject calls | Fix the typo to `"s3:GetObject"` | 100 | 5m |
| 4 | `level-4-wrong-resource` | The Locked Vault | Policy grants `s3:GetObject` on `arn:aws:s3:::wrong-bucket/*` but app reads from `mission-bucket` | Fix the resource ARN to point to the correct bucket | 125 | 8m |
| 5 | `level-5-no-policy` | The Bare Role | IAM role exists and is attached to Lambda but has zero policies — all calls denied | Attach a managed policy or put an inline policy granting required permissions | 125 | 8m |
| 6 | `level-6-wrong-principal` | Trust Nobody | Role trust policy has wrong account ID in Principal — `sts:AssumeRole` fails | Fix the Principal to the correct account ID (`000000000000` in LocalStack) | 150 | 10m |
| 7 | `level-7-wrong-service-principal` | Wrong Service | Lambda execution role has `"Service": "ec2.amazonaws.com"` in trust policy — Lambda can't assume it | Change service principal to `"lambda.amazonaws.com"` | 150 | 10m |
| 8 | `level-8-missing-passrole` | The Blocked Handoff | IAM user can create Lambda but can't assign an execution role — missing `iam:PassRole` | Add `iam:PassRole` permission on the target role to the user policy | 175 | 10m |
| 9 | `level-9-user-no-group` | The Orphan User | IAM user exists but is in no group and has no policies attached | Create a group with a policy, add the user to the group | 125 | 8m |
| 10 | `level-10-group-no-policy` | The Empty Club | User is in a group but the group has no policies — all actions denied | Attach a policy to the group | 125 | 8m |
| 11 | `level-11-condition-wrong-key` | The Bad Condition | Policy has a condition block using wrong key: `"aws:sourceIp"` when it should be `"aws:SourceAccount"` — condition never matches | Fix the condition key to the correct one | 175 | 12m |
| 12 | `level-12-condition-operator` | Almost Right | Policy condition uses `StringEquals` for a value that requires wildcard matching — use `StringLike` | Change condition operator from `StringEquals` to `StringLike` | 175 | 12m |
| 13 | `level-13-policy-missing-version` | Time Traveler | IAM policy document missing `"Version": "2012-10-17"` — policy variables don't resolve | Add the Version field to the policy document | 125 | 8m |
| 14 | `level-14-inline-blocks-managed` | Double Trouble | Inline policy grants S3 access but a second inline policy explicitly Denies it — Deny wins | Remove or fix the conflicting Deny policy | 200 | 15m |
| 15 | `level-15-assume-role-no-sts` | Can't Switch Hats | User policy is missing `sts:AssumeRole` — cannot switch to the target role | Add `sts:AssumeRole` on the target role ARN | 150 | 10m |
| 16 | `level-16-external-id-missing` | The Missing Secret Handshake | Role trust policy requires `sts:ExternalId` condition but caller doesn't provide it — AssumeRole denied | Provide the correct ExternalId when calling `aws sts assume-role` | 200 | 15m |
| 17 | `level-17-permission-boundary` | The Invisible Ceiling | IAM role has a permission boundary that blocks S3 access even though the identity policy allows it | Update or remove the permission boundary to allow the required actions | 225 | 15m |
| 18 | `level-18-resource-wildcard` | Scope Creep | Policy uses specific object ARN `arn:aws:s3:::bucket/specific.txt` but app accesses multiple objects — only that file is allowed | Change resource to `arn:aws:s3:::bucket/*` | 125 | 8m |
| 19 | `level-19-path-mismatch` | The Wrong Path | IAM user exists at path `/ops/` but policy ARN references `/dev/` — condition on path fails | Fix the role/user path or the policy path condition | 175 | 12m |
| 20 | `level-20-policy-size` | The Bloated Policy | Inline policy exceeds 2,048 character limit — IAM rejects the PutRolePolicy call | Refactor: extract into a managed policy and attach it | 200 | 15m |

---

## Module 2: S3 Mastery (20 Levels · Beginner · ~3,200 XP)

**Learning goal:** Master S3 buckets, policies, features, and common misconfigurations.  
**Tools used:** `aws s3`, `aws s3api`  
**LocalStack services:** S3

| # | Folder | Name | Broken State | Fix | XP | Time |
|---|--------|------|-------------|-----|----|------|
| 1 | `level-1-bucket-missing` | No Bucket, No Service | Application fails — target bucket `mission-bucket` doesn't exist | Create the bucket: `aws s3 mb s3://mission-bucket` | 100 | 5m |
| 2 | `level-2-access-denied-read` | Keep Out | Bucket exists and has an object but GetObject is denied — bucket policy blocks all access | Fix bucket policy to allow `s3:GetObject` for the required principal | 125 | 8m |
| 3 | `level-3-access-denied-write` | Read-Only Trap | Bucket policy only allows `s3:GetObject` — PutObject is denied | Add `s3:PutObject` to the bucket policy | 125 | 8m |
| 4 | `level-4-versioning-disabled` | Lost History | Application expects versioned objects but versioning is disabled — previous versions unreachable | Enable versioning: `aws s3api put-bucket-versioning` | 125 | 8m |
| 5 | `level-5-versioning-suspended` | Frozen in Time | Versioning is Suspended (not Enabled) — new versions are not created | Change versioning status from `Suspended` to `Enabled` | 150 | 10m |
| 6 | `level-6-public-access-block` | The Force Field | Bucket policy grants public read but `BlockPublicPolicy` is true — policy silently rejected | Disable public access block: `aws s3api put-public-access-block` | 150 | 10m |
| 7 | `level-7-cors-missing` | The CORS Complaint | Web application can't fetch objects — CORS configuration is missing entirely | Add a CORS configuration via `aws s3api put-bucket-cors` | 150 | 10m |
| 8 | `level-8-cors-wrong-origin` | Wrong Domain Allowed | CORS is configured but allows `https://wrong-app.com` instead of `https://myapp.com` | Fix the AllowedOrigins value in the CORS rule | 150 | 10m |
| 9 | `level-9-lifecycle-wrong-prefix` | Eternal Storage | Lifecycle rule exists to expire objects after 30 days but prefix is `logs/` while objects are under `app-logs/` — objects never expire | Fix the prefix in the lifecycle rule | 175 | 12m |
| 10 | `level-10-lifecycle-missing` | Incomplete Uploads Pile Up | Multipart uploads are being abandoned and accumulating cost — no lifecycle rule to abort them | Add lifecycle rule: abort incomplete multipart uploads after 7 days | 175 | 12m |
| 11 | `level-11-notification-missing` | Silent Arrivals | Lambda function should trigger on object upload — S3 event notification not configured | Add event notification: `aws s3api put-bucket-notification-configuration` | 175 | 12m |
| 12 | `level-12-notification-wrong-event` | Wrong Trigger | S3 event notification is configured but targets `s3:ObjectRemoved:*` instead of `s3:ObjectCreated:*` | Fix the event type in the notification configuration | 150 | 10m |
| 13 | `level-13-encryption-missing` | Plaintext Exposure | Bucket has no default encryption — objects stored unencrypted | Enable default SSE-S3 encryption: `aws s3api put-bucket-encryption` | 150 | 10m |
| 14 | `level-14-bucket-policy-syntax` | The Broken Gate | Bucket policy JSON has a syntax error (missing closing bracket) — policy rejected | Fix the JSON syntax in the bucket policy | 125 | 8m |
| 15 | `level-15-acl-too-open` | Public by Accident | Bucket ACL is set to `public-read` — all objects are publicly readable | Change ACL to `private`: `aws s3api put-bucket-acl --acl private` | 125 | 8m |
| 16 | `level-16-static-website-missing` | Silent Website | Static website hosting is disabled — requests return `NoSuchWebsiteConfiguration` | Enable static website hosting with index.html and error.html | 150 | 10m |
| 17 | `level-17-logging-disabled` | No Paper Trail | S3 server access logging is disabled — access logs not being collected | Enable logging: `aws s3api put-bucket-logging` | 150 | 10m |
| 18 | `level-18-object-lock-wrong-mode` | Too Flexible | Object lock is in `GOVERNANCE` mode but compliance requirements need `COMPLIANCE` mode | Change retention mode to `COMPLIANCE` on the object | 200 | 15m |
| 19 | `level-19-wrong-storage-class` | Expensive Archive | Frequently accessed objects are set to `GLACIER` storage class — retrieval takes hours | Change storage class to `STANDARD` via copy with metadata replacement | 175 | 12m |
| 20 | `level-20-requester-pays-wrong` | Unexpected Bills | Bucket has `requester-pays` enabled — callers are being charged unexpectedly | Disable requester pays: `aws s3api put-bucket-request-payment --payer BucketOwner` | 175 | 12m |

---

## Module 3: Lambda Functions (18 Levels · Beginner · ~3,150 XP)

**Learning goal:** Deploy, configure, and debug Lambda functions.  
**Tools used:** `aws lambda`, `aws iam`, `aws logs`  
**LocalStack services:** Lambda, IAM, S3, CloudWatch Logs

| # | Folder | Name | Broken State | Fix | XP | Time |
|---|--------|------|-------------|-----|----|------|
| 1 | `level-1-function-missing` | No Function Found | Invocation fails — Lambda function `mission-function` doesn't exist | Deploy the function using `aws lambda create-function` | 100 | 5m |
| 2 | `level-2-wrong-runtime` | Deprecated Engine | Function uses runtime `python3.6` (deprecated/unsupported) — invocation fails | Update runtime to `python3.11`: `aws lambda update-function-configuration` | 125 | 8m |
| 3 | `level-3-handler-wrong` | The Missing Door | Function is deployed but handler is `main.handler` — file is actually `index.py` with function `lambda_handler` | Fix handler to `index.lambda_handler` | 125 | 8m |
| 4 | `level-4-role-missing` | The Roleless Function | Function has no execution role set — invocation rejected | Create an IAM role with Lambda trust policy and assign it to the function | 150 | 10m |
| 5 | `level-5-role-wrong-service` | Wrong Trust | Execution role exists but trust policy has `ec2.amazonaws.com` instead of `lambda.amazonaws.com` | Fix the trust relationship on the role | 150 | 10m |
| 6 | `level-6-env-var-missing` | The Blank Config | Function code reads `os.environ['DATABASE_URL']` but the env var is not set — KeyError on invocation | Add the environment variable via `aws lambda update-function-configuration --environment` | 125 | 8m |
| 7 | `level-7-timeout-too-low` | Three Seconds and Out | Function needs 30 seconds to process but timeout is 3s — always times out | Increase timeout to 60s: `aws lambda update-function-configuration --timeout 60` | 125 | 8m |
| 8 | `level-8-memory-too-low` | Out of Memory | Function crashes with memory error — configured at 128MB, needs 512MB | Increase memory: `aws lambda update-function-configuration --memory-size 512` | 125 | 8m |
| 9 | `level-9-concurrency-zero` | The Throttled Function | Function has reserved concurrency set to `0` — all invocations are throttled immediately | Remove or increase reserved concurrency: `aws lambda put-function-concurrency` | 150 | 10m |
| 10 | `level-10-dlq-missing` | Lost on Failure | Async invocation fails silently — no dead-letter queue configured | Configure DLQ: `aws lambda update-function-configuration --dead-letter-config` | 175 | 12m |
| 11 | `level-11-layer-wrong-arn` | Missing Dependency | Function references a Lambda layer ARN that doesn't exist — init fails | Create the layer and update the function to use the correct ARN | 200 | 15m |
| 12 | `level-12-trigger-missing` | The Silent Upload | S3 bucket receives files but Lambda is never triggered — event source mapping missing | Add S3 notification configuration pointing to the Lambda function | 175 | 12m |
| 13 | `level-13-trigger-wrong-bucket` | Watching the Wrong Door | S3 trigger is configured but points to `wrong-bucket` instead of `uploads-bucket` | Fix the event source to point to the correct bucket | 150 | 10m |
| 14 | `level-14-resource-policy-missing` | Permission Denied by Lambda | S3 configured to invoke Lambda but Lambda resource policy doesn't allow S3 service | Add Lambda permission: `aws lambda add-permission` for `s3.amazonaws.com` principal | 200 | 15m |
| 15 | `level-15-alias-wrong-version` | The Ghost Alias | Lambda alias `production` points to version `5` which was deleted — invocations fail | Update alias to point to an existing version or `$LATEST` | 175 | 12m |
| 16 | `level-16-vpc-no-subnet` | Stranded in VPC | Lambda has VPC config but `SubnetIds` is empty — deployment fails | Add the correct subnet IDs to VPC configuration | 175 | 12m |
| 17 | `level-17-vpc-no-sg` | Unguarded VPC | Lambda VPC config has subnets but no security groups — cannot configure network interface | Add at least one security group to the VPC configuration | 175 | 12m |
| 18 | `level-18-function-url-auth` | The Locked Door | Lambda function URL is configured with `AuthType: AWS_IAM` — public HTTP requests return 403 | Change AuthType to `NONE` for public access: `aws lambda update-function-url-config` | 150 | 10m |

---

## Module 4: DynamoDB (15 Levels · Intermediate · ~3,375 XP)

**Learning goal:** Create and configure DynamoDB tables, indexes, and access patterns.  
**Tools used:** `aws dynamodb`  
**LocalStack services:** DynamoDB

| # | Folder | Name | Broken State | Fix | XP | Time |
|---|--------|------|-------------|-----|----|------|
| 1 | `level-1-table-missing` | No Table, No Data | Application fails — DynamoDB table `MissionTable` doesn't exist | Create the table with the correct key schema via `aws dynamodb create-table` | 150 | 8m |
| 2 | `level-2-wrong-key-type` | Type Mismatch | Table's hash key `userId` is defined as type `N` (Number) but application sends String values — all writes rejected | Delete and recreate table with hash key type `S` (String) | 200 | 12m |
| 3 | `level-3-missing-sort-key` | One Key Short | Table has only a hash key but the application queries with both hash + sort key — query fails | Recreate table with both partition key and sort key | 200 | 15m |
| 4 | `level-4-gsi-missing` | No Index, No Query | Application queries a GSI named `email-index` but the index doesn't exist on the table | Add the GSI via table update: `aws dynamodb update-table` | 250 | 15m |
| 5 | `level-5-gsi-wrong-key` | Wrong Index Key | GSI `email-index` exists but is keyed on `username` instead of `email` — queries return nothing | Delete the wrong GSI and create a new one with the correct key attribute | 250 | 15m |
| 6 | `level-6-capacity-throttle` | Out of Capacity | Table is in PROVISIONED mode with 1 RCU/WCU — application load causes constant throttling | Increase provisioned capacity or switch to PAY_PER_REQUEST | 200 | 12m |
| 7 | `level-7-billing-mode-wrong` | Provisionless Pain | Application has spiky unpredictable traffic but table is in PROVISIONED mode with no auto-scaling | Change billing mode to `PAY_PER_REQUEST` | 200 | 12m |
| 8 | `level-8-ttl-disabled` | Eternal Records | Application expects expired records to be cleaned up automatically — TTL is not enabled | Enable TTL on the `expiresAt` attribute: `aws dynamodb update-time-to-live` | 175 | 10m |
| 9 | `level-9-streams-disabled` | The Silent Table | Lambda should process every table change — DynamoDB Streams are disabled | Enable streams: `aws dynamodb update-table --stream-specification StreamEnabled=true` | 225 | 12m |
| 10 | `level-10-lsi-missing` | Local Index Gap | Application queries with a Local Secondary Index `status-index` that doesn't exist — LSI must be created at table creation time | Delete and recreate table with the LSI included | 275 | 20m |
| 11 | `level-11-projection-wrong` | Half the Picture | GSI `category-index` has `ProjectionType: KEYS_ONLY` but application needs all attributes | Delete the GSI and recreate it with `ProjectionType: ALL` | 250 | 15m |
| 12 | `level-12-pitr-disabled` | No Safety Net | Compliance requires Point-in-Time Recovery — it's disabled on the table | Enable PITR: `aws dynamodb update-continuous-backups` | 175 | 10m |
| 13 | `level-13-condition-blocks-write` | The Overprotective Guard | PutItem has a ConditionExpression `attribute_not_exists(id)` that prevents updating an existing item | Remove or change the condition expression to allow the update | 250 | 15m |
| 14 | `level-14-reserved-word-attr` | Reserved Words | Attribute name `status` is a DynamoDB reserved word — query using it as an expression attribute fails | Use Expression Attribute Names (`#s = :val`) in the query | 225 | 15m |
| 15 | `level-15-scan-instead-of-query` | Full Table Scan | Application uses `Scan` on a large table with a filter — extremely slow and expensive | Identify the proper key schema and rewrite as a `Query` operation | 300 | 20m |

---

## Module 5: SQS & SNS (15 Levels · Intermediate · ~3,375 XP)

**Learning goal:** Configure queues, topics, subscriptions, and common messaging pitfalls.  
**Tools used:** `aws sqs`, `aws sns`  
**LocalStack services:** SQS, SNS

| # | Folder | Name | Broken State | Fix | XP | Time |
|---|--------|------|-------------|-----|----|------|
| 1 | `level-1-queue-missing` | No Queue | Application sends messages but queue `mission-queue` doesn't exist | Create the SQS queue: `aws sqs create-queue` | 150 | 8m |
| 2 | `level-2-wrong-queue-url` | Wrong Address | Application is configured with an incorrect queue URL — messages going nowhere | Retrieve the correct URL: `aws sqs get-queue-url` and update the config | 150 | 8m |
| 3 | `level-3-visibility-too-low` | Message Ghost | Visibility timeout is 5 seconds — workers take 30s to process, messages become visible again and are re-processed | Increase visibility timeout to 60s: `aws sqs set-queue-attributes` | 200 | 12m |
| 4 | `level-4-dlq-missing` | No Safety Net | Queue has no Dead Letter Queue — failed messages disappear after max receive count | Create a DLQ and configure redrive policy on the source queue | 225 | 15m |
| 5 | `level-5-dlq-wrong-arn` | Lost DLQ | DLQ is configured but the ARN points to a non-existent queue — redrive fails silently | Fix the DLQ ARN in the redrive policy | 200 | 12m |
| 6 | `level-6-max-receive-zero` | Zero Tolerance | `maxReceiveCount` in redrive policy is set to `0` — messages go to DLQ immediately on first receive | Set `maxReceiveCount` to a reasonable value (e.g., 3) | 175 | 10m |
| 7 | `level-7-fifo-missing` | Order Ignored | Application requires ordered message processing (FIFO) but a Standard queue was created | Create a new FIFO queue (`.fifo` suffix) and update application config | 225 | 15m |
| 8 | `level-8-fifo-no-deduplication` | Duplicate Messages | FIFO queue exists but `ContentBasedDeduplication` is disabled and application doesn't provide `MessageDeduplicationId` — duplicates processed | Enable content-based deduplication on the FIFO queue | 200 | 12m |
| 9 | `level-9-queue-policy-missing` | SNS Can't Send | SNS topic configured to deliver to SQS queue but queue policy doesn't allow SNS to send — messages lost | Add queue policy allowing SNS service to `sqs:SendMessage` | 250 | 15m |
| 10 | `level-10-topic-missing` | No Topic | Application publishes to SNS topic `mission-topic` that doesn't exist | Create the SNS topic: `aws sns create-topic` | 150 | 8m |
| 11 | `level-11-subscription-missing` | Topic, No Subscribers | SNS topic exists but has no subscriptions — published messages go nowhere | Subscribe the SQS queue to the topic: `aws sns subscribe` | 175 | 10m |
| 12 | `level-12-subscription-wrong-endpoint` | Wrong Endpoint | SNS subscription exists but targets wrong SQS queue ARN | Delete and re-create subscription with correct endpoint ARN | 175 | 10m |
| 13 | `level-13-filter-policy-blocks-all` | The Silence Filter | SNS subscription has a filter policy `{"eventType": ["nonexistent"]}` — no messages pass through | Fix or remove the filter policy to allow relevant message attributes | 250 | 15m |
| 14 | `level-14-raw-delivery-missing` | Double-Wrapped | Lambda expects raw message body but SNS wraps it in an envelope — JSON parsing fails | Enable `RawMessageDelivery` on the SNS-to-SQS subscription | 225 | 15m |
| 15 | `level-15-message-too-large` | Message Size Exceeded | Application sends 300KB messages — SQS limit is 256KB — sends fail | Use the SQS Extended Client pattern: store payload in S3, send S3 reference in queue | 300 | 20m |

---

## Module 6: CloudWatch & Logging (15 Levels · Intermediate · ~3,375 XP)

**Learning goal:** Set up logging, metrics, alarms, and EventBridge rules.  
**Tools used:** `aws logs`, `aws cloudwatch`, `aws events`  
**LocalStack services:** CloudWatch Logs, CloudWatch Metrics, EventBridge

| # | Folder | Name | Broken State | Fix | XP | Time |
|---|--------|------|-------------|-----|----|------|
| 1 | `level-1-log-group-missing` | Where Are My Logs? | Lambda function writes logs but log group `/aws/lambda/mission-function` doesn't exist — logs dropped | Create the log group: `aws logs create-log-group` | 150 | 8m |
| 2 | `level-2-retention-not-set` | Infinite Log Growth | Log group exists but retention is set to `Never` — logs accumulate indefinitely | Set retention policy to 30 days: `aws logs put-retention-policy` | 150 | 8m |
| 3 | `level-3-log-stream-missing` | Stream Doesn't Exist | Application tries to write to a specific log stream that doesn't exist | Create the log stream: `aws logs create-log-stream` | 150 | 8m |
| 4 | `level-4-metric-filter-wrong-pattern` | Filter Catches Nothing | Metric filter exists to count ERROR logs but pattern is `[ERROR]` when logs use `ERROR:` format | Fix the filter pattern to match actual log format | 200 | 12m |
| 5 | `level-5-alarm-missing` | Silent Failure | Error metric is being published but no CloudWatch alarm is configured — nobody gets alerted | Create a CloudWatch alarm on the error metric | 200 | 12m |
| 6 | `level-6-alarm-wrong-threshold` | Always Firing | Alarm threshold is `0` — alarm fires constantly even with zero errors | Set a reasonable threshold (e.g., `5`) for the alarm | 175 | 10m |
| 7 | `level-7-alarm-no-action` | The Mute Alarm | Alarm fires (changes state to ALARM) but no action is configured — nobody is notified | Add SNS topic ARN to alarm actions: `aws cloudwatch put-metric-alarm` | 200 | 12m |
| 8 | `level-8-alarm-wrong-comparison` | Backwards Alarm | Alarm uses `LessThanThreshold` to detect high error counts — should be `GreaterThanThreshold` | Fix the comparison operator on the alarm | 175 | 10m |
| 9 | `level-9-alarm-wrong-period` | Too Granular | Alarm evaluation period is 10s but the metric is published every 5 minutes — alarm never evaluates | Fix period to match metric publish interval (300 seconds) | 200 | 12m |
| 10 | `level-10-log-insights-syntax` | Query Crash | CloudWatch Logs Insights query has a syntax error — query fails to execute | Fix the query syntax (check `fields`, `filter`, `stats` commands) | 225 | 15m |
| 11 | `level-11-event-rule-disabled` | Rule Is Off | EventBridge rule exists but its state is `DISABLED` — no events are delivered | Enable the rule: `aws events enable-rule` | 150 | 8m |
| 12 | `level-12-event-rule-wrong-target` | Wrong Destination | EventBridge rule has the wrong Lambda ARN as target | Update the rule target to the correct Lambda ARN | 175 | 10m |
| 13 | `level-13-event-pattern-wrong` | Mismatched Pattern | EventBridge rule has `"source": ["aws.ec3"]` (typo) instead of `"aws.ec2"` — events never match | Fix the event pattern | 175 | 10m |
| 14 | `level-14-composite-alarm-inverted` | Logic Flipped | Composite alarm uses `ALARM(alarm-a) AND NOT ALARM(alarm-b)` but should trigger when both are in ALARM | Fix the composite alarm rule expression | 275 | 18m |
| 15 | `level-15-missing-iam-for-logs` | No Permission to Write | Lambda execution role is missing `logs:CreateLogStream` and `logs:PutLogEvents` permissions | Add CloudWatch Logs permissions to the Lambda execution role | 225 | 12m |

---

## Module 7: EC2 & Networking (15 Levels · Intermediate · ~3,750 XP)

**Learning goal:** Configure security groups, VPC networking, and EC2 basics.  
**Tools used:** `aws ec2`  
**LocalStack services:** EC2, VPC

> Note: LocalStack free tier has partial EC2 support. Levels focus on security groups, VPCs, subnets, and route tables — areas with strong LocalStack support.

| # | Folder | Name | Broken State | Fix | XP | Time |
|---|--------|------|-------------|-----|----|------|
| 1 | `level-1-sg-missing` | No Security Group | Instance launch fails — no security group specified and no default SG exists in VPC | Create a security group and reference it in the instance config | 175 | 10m |
| 2 | `level-2-sg-no-inbound` | The Closed Door | Security group exists but has no inbound rules — all inbound traffic blocked (port 22, 80, 443) | Add inbound rules for the required ports | 175 | 10m |
| 3 | `level-3-sg-wrong-port` | Port Mismatch | Security group allows port 8080 inbound but application runs on port 80 | Fix the security group inbound rule to allow port 80 | 175 | 10m |
| 4 | `level-4-sg-wrong-cidr` | Too Restrictive CIDR | Security group inbound rule has CIDR `0.0.0.0/32` (single IP) instead of `0.0.0.0/0` | Fix the CIDR block on the inbound rule | 175 | 10m |
| 5 | `level-5-sg-egress-blocked` | No Way Out | Security group has a custom outbound rule that blocks all egress — app can't reach external APIs | Remove the blocking egress rule or add an allow-all egress rule | 200 | 12m |
| 6 | `level-6-vpc-missing` | No Network | Application requires a VPC with specific CIDR block — only the default VPC exists | Create a new VPC: `aws ec2 create-vpc --cidr-block 10.0.0.0/16` | 200 | 12m |
| 7 | `level-7-subnet-missing` | No Subnets | VPC exists but has no subnets — instances cannot be launched | Create public and private subnets in the VPC | 225 | 15m |
| 8 | `level-8-igw-not-attached` | Internet Gap | Internet gateway exists but is not attached to the VPC — no internet access | Attach the IGW to the VPC: `aws ec2 attach-internet-gateway` | 225 | 15m |
| 9 | `level-9-route-table-missing` | No Route to Internet | VPC, subnet, and IGW exist but route table has no route to `0.0.0.0/0` via IGW | Add route: `aws ec2 create-route --destination-cidr-block 0.0.0.0/0 --gateway-id igw-xxx` | 250 | 15m |
| 10 | `level-10-subnet-not-associated` | Route Table Orphan | Route table has correct routes but is not associated with the subnet | Associate route table with subnet: `aws ec2 associate-route-table` | 225 | 15m |
| 11 | `level-11-nacl-blocking-http` | Firewall in the Way | Network ACL has a DENY rule for port 80 with lower rule number than the ALLOW rule — HTTP blocked | Fix NACL rule order (lower rule number = higher priority) or remove the DENY rule | 275 | 18m |
| 12 | `level-12-iam-instance-profile-missing` | EC2 Can't Talk to AWS | Instance needs to call AWS APIs (SSM, S3) but has no IAM instance profile | Create instance profile with IAM role and associate it with the instance | 250 | 15m |
| 13 | `level-13-key-pair-missing` | No SSH Key | Instance launched without a key pair — SSH access impossible | Create a key pair and re-launch instance with it | 225 | 15m |
| 14 | `level-14-public-ip-disabled` | Invisible Instance | Instance in public subnet but `AssociatePublicIpAddress` is false — no public IP | Enable auto-assign public IP on the subnet or allocate an Elastic IP | 250 | 15m |
| 15 | `level-15-sg-missing-self-reference` | Cluster Can't Talk | Auto Scaling group instances need to communicate with each other — security group missing a self-referencing rule | Add an inbound rule referencing the security group ID as source | 275 | 18m |

---

## Module 8: CloudFormation (18 Levels · Intermediate · ~4,950 XP)

**Learning goal:** Write, debug, and manage CloudFormation stacks.  
**Tools used:** `aws cloudformation`  
**LocalStack services:** CloudFormation, IAM, S3, Lambda, SQS

| # | Folder | Name | Broken State | Fix | XP | Time |
|---|--------|------|-------------|-----|----|------|
| 1 | `level-1-yaml-syntax` | Parse Error | CFN template has a YAML indentation error — stack creation fails immediately | Fix the YAML syntax error in the template | 150 | 8m |
| 2 | `level-2-wrong-resource-type` | Unknown Resource | Template has `AWS::S3::Bukcet` (typo) instead of `AWS::S3::Bucket` — CREATE_FAILED | Fix the resource type name | 150 | 8m |
| 3 | `level-3-missing-required-property` | Missing Requirement | `AWS::SQS::Queue` resource is missing required `QueueName` — wait, QueueName is optional. `AWS::IAM::Role` missing `AssumeRolePolicyDocument` (required) | Add the missing required property | 175 | 10m |
| 4 | `level-4-parameter-no-default` | No Default Value | Template has a Parameter with no Default and no value passed at deploy — create fails | Either add a Default value or pass the parameter at stack creation | 175 | 10m |
| 5 | `level-5-parameter-wrong-type` | Type Collision | Parameter declared as `Type: Number` but value passed is a string — validation error | Fix parameter type or the value being passed | 175 | 10m |
| 6 | `level-6-ref-nonexistent` | Missing Reference | `!Ref MyBucket` references a logical ID `MyBucket` that doesn't exist in the template | Add the missing resource or fix the reference name | 175 | 10m |
| 7 | `level-7-getatt-wrong-attribute` | Wrong Attribute | `!GetAtt MyFunction.Arn` should be `!GetAtt MyFunction.FunctionArn` — depends on resource type | Fix the attribute name in the GetAtt reference | 200 | 12m |
| 8 | `level-8-circular-dependency` | Going in Circles | Resource A has `DependsOn: B` and B has `DependsOn: A` — circular dependency error | Break the circular dependency by removing one DependsOn or restructuring resources | 275 | 18m |
| 9 | `level-9-rollback-complete` | Stack Stuck | Stack is in `ROLLBACK_COMPLETE` state from a previous failed create — cannot update | Delete the stack and recreate it (stacks in ROLLBACK_COMPLETE can't be updated) | 200 | 12m |
| 10 | `level-10-output-export-duplicate` | Name Conflict | Two stacks both export a value with the same name `SharedBucketName` — second stack fails | Change the export name in one of the stacks to be unique | 225 | 15m |
| 11 | `level-11-importvalue-wrong-name` | Broken Cross-Stack Link | `!ImportValue SharedBucketName` — but the export is actually named `mission-SharedBucketName` | Fix the ImportValue key to match the exact export name | 200 | 12m |
| 12 | `level-12-condition-inverted` | Wrong Condition Logic | Condition `IsProduction: !Equals [!Ref Env, dev]` — logic is inverted (true when env is dev, not prod) | Fix the condition expression | 225 | 15m |
| 13 | `level-13-deletion-policy-delete` | Dangerous Delete | S3 bucket resource has no `DeletionPolicy` (defaults to Delete) — stack deletion will wipe data | Add `DeletionPolicy: Retain` to the bucket resource | 200 | 12m |
| 14 | `level-14-stack-policy-blocks` | Policy Lock | Stack update policy prevents changes to the S3 bucket resource — update fails | Update or remove the stack policy: `aws cloudformation set-stack-policy` | 250 | 15m |
| 15 | `level-15-mapping-wrong-key` | Missing Map Entry | `!FindInMap [RegionMap, !Ref AWS::Region, AMI]` — the `us-east-1` key is missing from the Mappings section | Add the missing key to the Mappings section | 200 | 12m |
| 16 | `level-16-transform-missing` | SAM Template Rejected | Template uses `AWS::Serverless::Function` but is missing `Transform: AWS::Serverless-2016-10-31` | Add the Transform declaration at the template root | 225 | 15m |
| 17 | `level-17-stack-drift` | Reality Diverged | Stack resources were manually modified outside CFN — stack has drifted | Detect drift: `aws cloudformation detect-stack-drift`, then reconcile by updating the stack | 300 | 20m |
| 18 | `level-18-nested-stack-wrong-url` | Nested Stack 404 | Nested stack references a template URL in S3 that doesn't exist or has wrong path | Upload the template to S3 and fix the TemplateURL property | 275 | 18m |

---

## Module 9: Secrets & Config (15 Levels · Advanced · ~4,500 XP)

**Learning goal:** Manage encryption keys, secrets, and configuration securely.  
**Tools used:** `aws kms`, `aws secretsmanager`, `aws ssm`  
**LocalStack services:** KMS, Secrets Manager, SSM Parameter Store

| # | Folder | Name | Broken State | Fix | XP | Time |
|---|--------|------|-------------|-----|----|------|
| 1 | `level-1-kms-key-missing` | No Key | Application tries to encrypt using KMS key alias `alias/mission-key` — key doesn't exist | Create a KMS key and alias: `aws kms create-key` + `aws kms create-alias` | 250 | 15m |
| 2 | `level-2-kms-key-disabled` | Disabled Key | KMS key exists but is disabled — encrypt/decrypt operations fail with `DisabledException` | Enable the key: `aws kms enable-key` | 225 | 12m |
| 3 | `level-3-kms-key-policy-missing` | No Key Permission | KMS key exists and is enabled but key policy doesn't grant the IAM role permission to use it | Update the key policy to grant `kms:Encrypt`, `kms:Decrypt` to the role | 300 | 18m |
| 4 | `level-4-kms-wrong-alias` | Wrong Key Name | Application uses `alias/production-key` but key was created with alias `alias/prod-key` | Create the correct alias or update application config | 225 | 12m |
| 5 | `level-5-secret-missing` | No Secret | Application calls `GetSecretValue` for `mission/db-password` — secret doesn't exist | Create the secret: `aws secretsmanager create-secret` | 250 | 15m |
| 6 | `level-6-secret-wrong-key` | Wrong Key in JSON | Secret exists as JSON `{"password": "abc123"}` but application reads key `db_password` | Update the secret value to use the correct JSON key | 250 | 15m |
| 7 | `level-7-secret-no-permission` | Access Denied to Secret | Secret exists but IAM role is missing `secretsmanager:GetSecretValue` permission | Add the required permission to the role policy | 275 | 15m |
| 8 | `level-8-secret-wrong-version` | Wrong Version | Application pinned to a specific secret version that no longer exists (was rotated) | Update application to use `AWSCURRENT` stage or fix the version reference | 300 | 18m |
| 9 | `level-9-secret-rotation-broken` | Stale Credentials | Secret rotation was configured but rotation Lambda ARN is wrong — secret is never rotated | Fix the rotation Lambda ARN: `aws secretsmanager rotate-secret` with correct config | 325 | 20m |
| 10 | `level-10-ssm-parameter-missing` | Missing Config | Application reads SSM parameter `/mission/config/db-host` — parameter doesn't exist | Create the parameter: `aws ssm put-parameter` | 225 | 12m |
| 11 | `level-11-ssm-wrong-type` | Plaintext Secret | SSM parameter `/mission/config/api-key` is stored as `String` type — should be `SecureString` (encrypted) | Delete and recreate as SecureString: `aws ssm put-parameter --type SecureString` | 250 | 15m |
| 12 | `level-12-ssm-wrong-path` | Path Confusion | Application reads `/production/db/password` but parameter was created at `/prod/db/password` | Create parameter at the correct path or fix the application path config | 225 | 12m |
| 13 | `level-13-ssm-no-permission` | SSM Blocked | ECS task role is missing `ssm:GetParameter` permission — task crashes at startup | Add `ssm:GetParameter` and `ssm:GetParameters` to the task role | 275 | 15m |
| 14 | `level-14-kms-key-rotation` | Rotation Breaks Decrypt | KMS key rotation was enabled but application has old key ARN hardcoded — decryption fails after rotation | Update application to use key alias instead of key ARN (aliases track rotation automatically) | 350 | 20m |
| 15 | `level-15-hardcoded-credentials` | Credentials in Code | Lambda function has `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` hardcoded in environment variables | Remove hardcoded credentials, create proper IAM execution role with required permissions | 375 | 25m |

---

## Module 10: ECS & Containers (15 Levels · Advanced · ~4,500 XP)

**Learning goal:** Deploy and debug containerized workloads on ECS with Fargate.  
**Tools used:** `aws ecs`, `aws ecr`, `aws iam`  
**LocalStack services:** ECS, ECR, IAM, CloudWatch Logs

| # | Folder | Name | Broken State | Fix | XP | Time |
|---|--------|------|-------------|-----|----|------|
| 1 | `level-1-cluster-missing` | No Cluster | ECS service create fails — cluster `mission-cluster` doesn't exist | Create cluster: `aws ecs create-cluster --cluster-name mission-cluster` | 225 | 12m |
| 2 | `level-2-task-definition-missing` | No Task Definition | Service references task definition `mission-task` with no revision registered | Register the task definition: `aws ecs register-task-definition` | 250 | 15m |
| 3 | `level-3-wrong-cpu-memory` | Invalid Config | Fargate task definition has CPU `256` with memory `256` — Fargate requires memory >= 512MB for 256 CPU units | Fix memory to a valid Fargate combination (256 CPU → 512, 1024, or 2048 MB) | 250 | 15m |
| 4 | `level-4-execution-role-missing` | Can't Pull Image | Task fails to start — no `executionRoleArn` set, so ECS can't pull the ECR image or write logs | Create execution role with `AmazonECSTaskExecutionRolePolicy` and attach it | 275 | 15m |
| 5 | `level-5-task-role-wrong-perms` | App Can't Access AWS | Task starts but application inside container can't read from S3 — task role has no S3 permission | Add S3 read permissions to the task IAM role | 275 | 15m |
| 6 | `level-6-ecr-image-missing` | No Image Found | Task definition references ECR image that doesn't exist — task fails to pull | Push a valid image to ECR: `docker build`, `aws ecr get-login-password`, `docker push` | 300 | 20m |
| 7 | `level-7-container-port-wrong` | Port Mismatch | Task definition exposes port 8080 but load balancer target group expects port 80 | Fix containerPort in task definition or update target group | 275 | 15m |
| 8 | `level-8-service-desired-zero` | Zero Tasks | Service exists but `desiredCount` is 0 — no tasks running | Update service: `aws ecs update-service --desired-count 2` | 225 | 12m |
| 9 | `level-9-env-var-missing` | App Crash at Startup | Task starts but application crashes because required env var `APP_MODE` not in task definition | Add the environment variable to the task definition container config | 250 | 15m |
| 10 | `level-10-secrets-wrong-arn` | Secret Not Found | Task definition references Secrets Manager ARN that doesn't exist — task fails to start | Fix the ARN in the `secrets` section of the task definition | 300 | 18m |
| 11 | `level-11-health-check-wrong` | Permanently Unhealthy | Container health check command is `CMD ["curl", "http://localhost/wrong-path"]` — always fails | Fix the health check path to match the actual application health endpoint | 275 | 15m |
| 12 | `level-12-log-driver-wrong` | No Logs | Task definition uses `journald` log driver — ECS Fargate only supports `awslogs` | Change `logDriver` to `awslogs` and configure the `awslogs-group` option | 275 | 15m |
| 13 | `level-13-subnet-no-nat` | No Internet in Private | Fargate task in private subnet with no NAT gateway — task can't pull image or reach AWS APIs | Either move to public subnet or note that NAT gateway is needed (add route via NAT) | 325 | 20m |
| 14 | `level-14-sg-no-outbound` | Locked Container | Security group has no outbound rules — task can't pull image or call AWS services | Add egress rule allowing all outbound: `0.0.0.0/0` | 250 | 15m |
| 15 | `level-15-service-discovery-missing` | Can't Find Service | Service A tries to reach Service B via DNS `service-b.local` — no Cloud Map service discovery configured | Set up AWS Cloud Map namespace and service, link to ECS service | 375 | 25m |

---

## Module 11: API Gateway (12 Levels · Advanced · ~3,900 XP)

**Learning goal:** Build and debug REST APIs with Lambda integrations.  
**Tools used:** `aws apigateway`, `aws lambda`  
**LocalStack services:** API Gateway, Lambda, IAM

| # | Folder | Name | Broken State | Fix | XP | Time |
|---|--------|------|-------------|-----|----|------|
| 1 | `level-1-api-missing` | No API Exists | REST API `mission-api` doesn't exist — client gets connection refused | Create the REST API: `aws apigateway create-rest-api` | 250 | 15m |
| 2 | `level-2-resource-missing` | No Path Configured | API exists but the `/items` resource path doesn't exist — 404 on all requests | Create the resource: `aws apigateway create-resource` with correct path part | 250 | 15m |
| 3 | `level-3-method-wrong` | Wrong HTTP Method | `POST /items` resource only has a `GET` method configured — POST returns 405 | Add a POST method to the resource | 275 | 15m |
| 4 | `level-4-integration-missing` | No Backend | Method exists but has no integration — request returns empty 200 | Add Lambda proxy integration: `aws apigateway put-integration` | 300 | 18m |
| 5 | `level-5-integration-wrong-arn` | Wrong Lambda | Integration exists but Lambda ARN points to non-existent function | Fix the URI in the integration to use the correct Lambda ARN | 275 | 15m |
| 6 | `level-6-lambda-permission-missing` | API Can't Invoke Lambda | Integration is correct but API Gateway can't invoke Lambda — missing resource policy | Add Lambda permission: `aws lambda add-permission` for `apigateway.amazonaws.com` | 300 | 18m |
| 7 | `level-7-not-deployed` | API Not Live | API is fully configured but never deployed to a stage — all requests fail | Deploy the API: `aws apigateway create-deployment --stage-name prod` | 250 | 15m |
| 8 | `level-8-cors-missing` | CORS Error | API works from CLI but web browser gets CORS error — OPTIONS method and CORS headers not configured | Enable CORS on the resource (add OPTIONS method + response headers) | 325 | 20m |
| 9 | `level-9-throttle-zero` | All Requests Throttled | Stage has `throttlingBurstLimit: 0` and `throttlingRateLimit: 0` — every request throttled | Update stage settings to allow reasonable throttle limits | 275 | 15m |
| 10 | `level-10-auth-wrong` | Authorization Required | API requires AWS_IAM authorization but client expects no auth — all requests 403 | Change method authorization to `NONE` or provide correct SigV4 headers | 325 | 20m |
| 11 | `level-11-mapping-template-wrong` | Garbled Request | Mapping template transforms request body but uses wrong field name — Lambda receives null values | Fix the VTL mapping template to correctly map request fields | 375 | 25m |
| 12 | `level-12-api-key-no-plan` | API Key Rejected | API requires API key but no usage plan exists associating the key to the stage | Create usage plan, associate API stage, and link API key to usage plan | 375 | 25m |

---

## Module 12: Production War Games (18 Levels · Expert · ~7,200 XP)

**Learning goal:** Debug complex multi-service failures that mirror real-world production incidents.  
Each war game has 2–4 simultaneous issues to find and fix.  
**Tools used:** All previous services  
**LocalStack services:** All services

| # | Folder | Name | Broken State (Multiple Issues) | XP | Time |
|---|--------|------|-------------------------------|-----|------|
| 1 | `level-1-lambda-cant-read-s3` | The Blocked Pipeline | Lambda role missing `s3:GetObject` AND bucket policy has explicit Deny for Lambda role | 400 | 25m |
| 2 | `level-2-sns-sqs-lambda-broken` | The Silent Chain | SNS→SQS→Lambda pipeline: SQS queue policy missing (SNS can't send) + Lambda concurrency is 0 | 450 | 30m |
| 3 | `level-3-alarm-never-fires` | The Blind System | Error metric filter uses wrong pattern + alarm threshold inverted + alarm has no SNS action | 450 | 30m |
| 4 | `level-4-s3-trigger-broken` | Upload Goes Nowhere | S3 event notification on wrong bucket + Lambda resource policy missing principal + DLQ not configured | 450 | 30m |
| 5 | `level-5-api-gateway-full-break` | The Dead API | API deployed to wrong stage + Lambda ARN wrong + CORS missing + throttle is zero | 500 | 35m |
| 6 | `level-6-ecs-wont-start` | Container Chaos | ECS task: execution role missing + wrong ECR image ARN + health check command wrong | 500 | 35m |
| 7 | `level-7-dynamodb-lambda-stream` | Stream Silence | DynamoDB Streams disabled + Lambda event source mapping wrong stream ARN + Lambda role missing `dynamodb:GetRecords` | 475 | 30m |
| 8 | `level-8-cfn-stack-broken` | Stack Refuses to Update | Stack in ROLLBACK_COMPLETE + export name conflict + deletion policy missing on RDS | 475 | 35m |
| 9 | `level-9-secrets-rotation-cascade` | The Credential Crisis | Secret ARN changed after rotation + Lambda env var has old ARN + IAM policy uses ARN not name | 500 | 35m |
| 10 | `level-10-cross-account-role` | The Missing Bridge | Assume-role fails: wrong Principal in trust policy + missing ExternalId condition + user missing sts:AssumeRole | 500 | 35m |
| 11 | `level-11-iam-privilege-escalation` | Security Audit | Role has `iam:CreateRole` + `iam:AttachRolePolicy` + `iam:PassRole` — can create admin role and escalate | Identify and remove over-permissive IAM capabilities | 550 | 40m |
| 12 | `level-12-public-s3-exposure` | Data Exposure Incident | S3 bucket has public access block disabled + bucket ACL is public-read + bucket policy allows `*` principal | Find all three vectors and lock down the bucket | 550 | 40m |
| 13 | `level-13-sqs-message-pileup` | Queue Meltdown | DLQ ARN wrong in redrive policy + visibility timeout too low + no alarm on DLQ depth | 475 | 30m |
| 14 | `level-14-cloudwatch-observability-gap` | Flying Blind | Lambda has no log group + metric filter on wrong log group + alarm period mismatch + no SNS action | 500 | 35m |
| 15 | `level-15-ecs-networking-labyrinth` | The Unreachable Service | ECS task in private subnet + no NAT route + security group blocks 443 egress + execution role missing ecr permission | 550 | 40m |
| 16 | `level-16-kms-breaks-everything` | Encryption Lockout | KMS key disabled + key policy missing IAM role + Lambda uses hardcoded key ARN (not alias) after rotation | 550 | 40m |
| 17 | `level-17-api-auth-lockout` | The Auth Maze | API Gateway: IAM auth enabled + Lambda permission missing + usage plan throttle is zero + CORS blocks browser | 575 | 45m |
| 18 | `level-18-full-stack-incident` | The Production Incident | Complete app stack broken: CloudFormation drift + IAM permission removed + S3 bucket policy expired + Lambda concurrency at 0 + CloudWatch alarm silenced | 600 | 60m |

---

## Implementation Notes for AI

### Each module directory structure

```
modules/
  module-1-iam/
    level-1-empty-policy/
      mission.yaml      ← name, description, objective, xp, difficulty, expected_time, concepts
      setup.sh          ← executable, creates broken state in LocalStack using aws CLI
      validate.sh       ← executable, exits 0=pass, 1=fail with descriptive message
      solution.md       ← step-by-step aws CLI commands to fix the issue
      hint-1.txt        ← vague first hint (point toward the problem area)
      hint-2.txt        ← more specific second hint (name the broken attribute)
      hint-3.txt        ← near-solution third hint (show the command structure)
      debrief.md        ← why this matters in real AWS, common real-world scenario
```

### setup.sh requirements

- Always use `#!/usr/bin/env bash` and `set -e`
- Use `ENDPOINT="http://localhost:4566"` for all `--endpoint-url` args
- Use `AWS_DEFAULT_REGION=us-east-1` and `ACCOUNT="000000000000"` (LocalStack default)
- End with an `echo` describing the broken state
- Keep it idempotent where possible (use `||true` on creates that might already exist)
- For Lambda levels: include a minimal valid `function.zip` in the level directory OR create it inline in setup.sh using Python's zipfile

### validate.sh requirements

- Always use `#!/usr/bin/env bash`
- Do NOT use `set -e` at top — use explicit error handling
- Last line must be either `exit 0` (pass) or `exit 1` (fail)
- Before `exit 1`, print a helpful FAIL message pointing to what's still wrong
- Before `exit 0`, print a PASS message confirming what was fixed
- Test the actual state in LocalStack, not just whether a resource exists

### solution.md format

```markdown
# Solution: [Level Name]

## The Problem
[1-2 sentences explaining what was broken and why it matters]

## Fix

\`\`\`bash
# Step 1: [description]
aws iam put-role-policy \
  --role-name lambda-execution-role \
  --policy-name fixed-policy \
  --policy-document '{"Version":"2012-10-17","Statement":[...]}'
\`\`\`

## Verify
\`\`\`bash
aws iam get-role-policy \
  --role-name lambda-execution-role \
  --policy-name fixed-policy
\`\`\`
```

### mission.yaml format

```yaml
name: "Human-readable level title"
description: "1-2 sentences describing the symptom the player sees"
objective: "1 sentence: what the player must do to fix it"
xp: 150
difficulty: "beginner"   # beginner | intermediate | advanced | expert
expected_time: "10m"
concepts:
  - IAM policy
  - Effect: Allow
  - Statement array
module: "module-1-iam"
level: "level-1-empty-policy"
```

### levels.json format (auto-generated by scripts/build_levels.py)

Mirrors the structure of k8smissions and terraformissions:
```json
{
  "generated_at": "ISO timestamp",
  "level_count": 196,
  "modules": [
    {
      "name": "module-1-iam",
      "levels": [
        {
          "id": "module-1-iam/level-1-empty-policy",
          "name": "level-1-empty-policy",
          "path": "modules/module-1-iam/level-1-empty-policy",
          "mission": { ...mission.yaml contents... }
        }
      ]
    }
  ]
}
```

### LocalStack account ID

LocalStack uses account ID `000000000000` for all ARNs. All `setup.sh` and `validate.sh` scripts must use this account ID in ARN constructions.

### Lambda function.zip for Lambda levels

For levels that need to deploy a Lambda function, include a minimal `index.py` in the level directory and have `setup.sh` create `function.zip` inline:

```bash
cd /tmp
cat > index.py << 'EOF'
import json
def lambda_handler(event, context):
    return {"statusCode": 200, "body": json.dumps("OK")}
EOF
zip function.zip index.py
aws --endpoint-url=$ENDPOINT lambda create-function \
  --function-name mission-function \
  --runtime python3.11 \
  --role arn:aws:iam::$ACCOUNT:role/execution-role \
  --handler index.lambda_handler \
  --zip-file fileb://function.zip
rm -f index.py function.zip
cd -
```
