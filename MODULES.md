# AWSMissions Curriculum

Generated from each level's `mission.yaml` by `scripts/build_levels.py`. Do not edit by hand.

**268 missions across 16 modules.**

## Module 1: IAM Foundations (21 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | The Half-Open Door | beginner | 100 | IAM inline policies, s3:GetObject, bucket vs object ARNs, least privilege | `level-1-empty-policy` |
| 2 | Wrong Side of the Law | beginner | 100 | IAM policy evaluation, explicit Deny, s3:PutObject | `level-2-deny-effect` |
| 3 | Fat Fingers | beginner | 100 | IAM action names, implicit deny, least privilege | `level-3-action-typo` |
| 4 | Right Queue, Wrong Address | beginner | 125 | IAM resource ARNs, SQS ARNs, region and account in ARNs | `level-4-wrong-resource` |
| 5 | The Bare Role | beginner | 125 | Lambda execution roles, identity policies, least privilege | `level-5-no-policy` |
| 6 | Trust Issues | intermediate | 150 | role trust policies, IAM principals and ARNs, cross-account migrations | `level-6-wrong-principal` |
| 7 | Cloned Credentials | intermediate | 175 | trust policy principal types, Service vs AWS principals, break-glass access | `level-7-wrong-service-principal` |
| 8 | Dropped Baton | intermediate | 200 | iam:PassRole, privilege escalation, Lambda execution roles | `level-8-missing-passrole` |
| 9 | First Day, No Access | intermediate | 150 | IAM groups, group membership, least privilege | `level-9-user-no-group` |
| 10 | The Empty Club | intermediate | 175 | IAM groups, managed policies, attaching policies, least privilege | `level-10-group-no-policy` |
| 11 | Data Stays in Europe | intermediate | 200 | IAM condition keys, aws:RequestedRegion, data residency guardrails | `level-11-condition-wrong-key` |
| 12 | Almost, But Not Quite | intermediate | 200 | IAM condition operators, StringEquals vs StringLike, s3:prefix | `level-12-condition-operator` |
| 13 | Dollar Signs Without Meaning | intermediate | 225 | IAM policy variables, policy Version element, managed policy versions | `level-13-policy-missing-version` |
| 14 | Frozen in Time | advanced | 250 | explicit Deny, inline vs managed policies, policy evaluation logic | `level-14-inline-blocks-managed` |
| 15 | One Hat Short | intermediate | 225 | sts:AssumeRole, identity-based permission to assume a role, same-account trust | `level-15-assume-role-no-sts` |
| 16 | The Secret Handshake | advanced | 300 | sts:ExternalId, confused deputy problem, third-party access | `level-16-external-id-missing` |
| 17 | The Invisible Ceiling | advanced | 325 | permissions boundaries, effective permissions (intersection), managed policy versions | `level-17-permission-boundary` |
| 18 | Scope Creep | advanced | 300 | resource wildcards, over-permissive policies, least privilege | `level-18-resource-wildcard` |
| 19 | Lost in the Path | expert | 400 | IAM paths, user ARNs, policy variables, self-service credentials | `level-19-path-mismatch` |
| 20 | The Bloated Policy | expert | 450 | IAM policy size limits, inline vs managed policies, policy consolidation | `level-20-policy-size` |
| 21 | Guest List Gone Wrong | advanced | 275 | resource-based policies, S3 bucket policies, principals in bucket policies | `level-21-bucket-policy-principal` |

## Module 2: S3 Mastery (20 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | Manifest Not Found | beginner | 75 | S3 bucket names, bucket creation, NoSuchBucket | `level-1-bucket-missing` |
| 2 | Keep Out | beginner | 100 | bucket policies, Principal element, object ARN prefixes | `level-2-access-denied-read` |
| 3 | Read-Only Trap | beginner | 100 | bucket policies, object vs bucket ARNs, s3:PutObject | `level-3-access-denied-write` |
| 4 | Lost History | beginner | 100 | S3 versioning, object versions, overwrite protection | `level-4-versioning-disabled` |
| 5 | Suspended Animation | beginner | 150 | suspended versioning, null version, restoring an object version | `level-5-versioning-suspended` |
| 6 | The Force Field | intermediate | 175 | S3 Block Public Access, BlockPublicPolicy, public bucket policies | `level-6-public-access-block` |
| 7 | The CORS Complaint | beginner | 125 | CORS, preflight requests, AllowedOrigins, ExposeHeaders | `level-7-cors-missing` |
| 8 | Wrong Domain Allowed | intermediate | 175 | CORS, AllowedOrigins matching, per-origin rules | `level-8-cors-wrong-origin` |
| 9 | Eternal Storage | intermediate | 150 | S3 lifecycle rules, rule filters and prefixes, Expiration | `level-9-lifecycle-wrong-prefix` |
| 10 | Incomplete Uploads Pile Up | intermediate | 200 | multipart uploads, AbortIncompleteMultipartUpload, lifecycle configuration replacement | `level-10-lifecycle-missing` |
| 11 | Silent Arrivals | intermediate | 175 | S3 event notifications, SQS destinations, prefix and suffix filters | `level-11-notification-missing` |
| 12 | Wrong Trigger | intermediate | 175 | S3 event types, ObjectCreated vs ObjectRemoved, notification configuration replacement | `level-12-notification-wrong-event` |
| 13 | Plaintext Exposure | intermediate | 200 | default bucket encryption, SSE-KMS, customer managed keys, encrypting existing objects | `level-13-encryption-missing` |
| 14 | The Broken Gate | advanced | 275 | bucket policy debugging, Principal ARNs, Action names, condition operators (StringEquals vs StringLike) | `level-14-bucket-policy-syntax` |
| 15 | Public by Accident | intermediate | 150 | S3 ACLs, object ownership, public access, AllUsers grantee | `level-15-acl-too-open` |
| 16 | Silent Website | intermediate | 175 | S3 static website hosting, index document, error document | `level-16-static-website-missing` |
| 17 | No Paper Trail | advanced | 275 | S3 server access logging, log delivery permissions, service principals in bucket policies | `level-17-logging-disabled` |
| 18 | Too Flexible | expert | 400 | S3 Object Lock, governance vs compliance retention, default retention, per-version retention | `level-18-object-lock-wrong-mode` |
| 19 | Expensive Archive | advanced | 250 | storage classes, lifecycle transitions, copy-object metadata directive | `level-19-wrong-storage-class` |
| 20 | Unexpected Bills | intermediate | 200 | Requester Pays, bucket payer configuration, auditing many buckets | `level-20-requester-pays-wrong` |

## Module 3: Lambda Functions (20 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | Return to Sender | beginner | 75 | Lambda deployment packages, create-function, handler naming | `level-1-function-missing` |
| 2 | End of the Line | beginner | 100 | Lambda runtimes, runtime deprecation, update-function-configuration | `level-2-wrong-runtime` |
| 3 | Wrong Door, Right House | beginner | 100 | Lambda handler, Node.js ES modules, Lambda init errors | `level-3-handler-wrong` |
| 4 | Nobody Home | beginner | 125 | Lambda execution role, trust policy, least privilege | `level-4-role-missing` |
| 5 | Borrowed Badge | beginner | 125 | IAM trust policy, service principals, update-assume-role-policy | `level-5-role-wrong-service` |
| 6 | The Blank Config | intermediate | 150 | Lambda environment variables, update-function-configuration, DynamoDB, execution role permissions | `level-6-env-var-missing` |
| 7 | Three Seconds and Out | intermediate | 150 | Lambda timeout, function configuration limits, API integration limits | `level-7-timeout-too-low` |
| 8 | Out of Memory | intermediate | 175 | Lambda memory, out of memory, cost control | `level-8-memory-too-low` |
| 9 | The Throttled Function | intermediate | 175 | reserved concurrency, throttling, protecting downstream resources | `level-9-concurrency-zero` |
| 10 | Lost on Failure | intermediate | 200 | asynchronous invocation, on-failure destinations, event invoke config | `level-10-dlq-missing` |
| 11 | Missing Dependency | intermediate | 225 | Lambda layers, layer versions, update-function-configuration | `level-11-layer-wrong-arn` |
| 12 | The Silent Upload | advanced | 250 | S3 event notifications, notification filters, Lambda triggers | `level-12-trigger-missing` |
| 13 | Watching the Wrong Door | advanced | 250 | S3 event notifications, environment separation, Lambda triggers | `level-13-trigger-wrong-bucket` |
| 14 | Permission Denied by Lambda | advanced | 275 | Lambda resource-based policy, add-permission, cross-principal access | `level-14-resource-policy-missing` |
| 15 | The Ghost Alias | advanced | 275 | Lambda versions, aliases, safe releases | `level-15-alias-wrong-version` |
| 16 | Stranded in VPC | advanced | 325 | Lambda VPC configuration, private vs public subnets, availability zones | `level-16-vpc-no-subnet` |
| 17 | Unguarded VPC | advanced | 350 | security groups, security group references, Lambda VPC configuration | `level-17-vpc-no-sg` |
| 18 | The Locked Door | advanced | 350 | Lambda function URLs, AuthType NONE, resource-based policy, CORS | `level-18-function-url-auth` |
| 19 | Bad Apple in the Batch | expert | 450 | SQS event source mapping, partial batch response, dead-letter queues, idempotency | `level-19-sqs-poison-batch` |
| 20 | Fenced In | expert | 400 | IAM permissions boundary, effective permissions, managed policy versions | `level-20-role-boundary` |

## Module 4: DynamoDB (16 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | No Table, No Orders | beginner | 90 | DynamoDB tables, partition key and sort key, on-demand billing | `level-1-table-missing` |
| 2 | Numbers Don't Look Like UUIDs | beginner | 100 | DynamoDB attribute types, immutable key schema, deletion protection | `level-2-wrong-key-type` |
| 3 | History Keeps Vanishing | beginner | 110 | sort keys, item identity, range queries | `level-3-missing-sort-key` |
| 4 | Login by Email | intermediate | 150 | global secondary index, alternate access patterns, index backfill | `level-4-gsi-missing` |
| 5 | The Index That Knew the Wrong Thing | intermediate | 175 | GSI key schema, recreating an index, sort key on an index | `level-5-gsi-wrong-key` |
| 6 | Five Units Against a Flood | intermediate | 200 | provisioned capacity, Application Auto Scaling, target tracking | `level-6-capacity-throttle` |
| 7 | Flash Sale Pricing | intermediate | 175 | on-demand billing, billing mode switch, capacity leftovers | `level-7-billing-mode-wrong` |
| 8 | Sessions That Never Die | intermediate | 200 | DynamoDB TTL, epoch-second timestamps, eventual deletion | `level-8-ttl-disabled` |
| 9 | The Silent Table | intermediate | 200 | DynamoDB Streams, stream view type, change data capture | `level-9-streams-disabled` |
| 10 | The Index You Can't Add Later | advanced | 275 | local secondary index, table migration, immutable table design | `level-10-lsi-missing` |
| 11 | Half the Picture | advanced | 250 | index projections, KEYS_ONLY vs INCLUDE vs ALL, index cost | `level-11-projection-wrong` |
| 12 | The Audit Nobody Wanted | intermediate | 225 | point-in-time recovery, resource tags, compliance scope | `level-12-pitr-disabled` |
| 13 | The Overprotective Guard | advanced | 275 | ConditionExpression, optimistic locking, conditional updates | `level-13-condition-blocks-write` |
| 14 | Words You Cannot Say | intermediate | 225 | reserved words, ExpressionAttributeNames, UpdateExpression | `level-14-reserved-word-attr` |
| 15 | Scan Is Not a Query | expert | 400 | Scan vs Query, GSI design, IAM for DynamoDB indexes, least privilege | `level-15-scan-instead-of-query` |
| 16 | Tenants Behind Glass | advanced | 325 | fine-grained access control, dynamodb:LeadingKeys, multi-tenant isolation | `level-16-tenant-leading-keys` |

## Module 5: SQS & SNS (17 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | Typo at the Dock | beginner | 75 | SQS queues, queue naming, long polling | `level-1-queue-missing` |
| 2 | Staging Is Not Production | beginner | 100 | SQS queue URL, get-queue-url, Parameter Store configuration | `level-2-wrong-queue-url` |
| 3 | The Label That Printed Twice | beginner | 100 | visibility timeout, at-least-once delivery, SQS queue attributes | `level-3-visibility-too-low` |
| 4 | Poison Pill | intermediate | 150 | dead-letter queues, redrive policy, maxReceiveCount, message retention | `level-4-dlq-missing` |
| 5 | The Dead Letter Gets Lost | intermediate | 150 | dead-letter queues, redrive policy, queue ARN | `level-5-dlq-wrong-arn` |
| 6 | One Strike | intermediate | 175 | maxReceiveCount, redrive policy tuning, transient vs permanent failure | `level-6-max-receive-zero` |
| 7 | Out of Order | intermediate | 150 | FIFO queues, message groups, ordering guarantees | `level-7-fifo-missing` |
| 8 | Twice Charged | intermediate | 175 | FIFO deduplication, ContentBasedDeduplication, exactly-once processing | `level-8-fifo-no-deduplication` |
| 9 | Locked Mailbox | intermediate | 225 | SQS queue policy, service principal, aws:SourceArn condition, confused deputy | `level-9-queue-policy-missing` |
| 10 | Storm Warning, No Station | beginner | 100 | SNS topics, subscriptions die with their topic, SNS to SQS fan-out | `level-10-topic-missing` |
| 11 | Nobody Told Loyalty | beginner | 125 | SNS subscriptions, fan-out, subscription ARN vs endpoint | `level-11-subscription-missing` |
| 12 | Wrong Mailbox | intermediate | 150 | SNS subscription endpoint, immutable subscription attributes, environment isolation | `level-12-subscription-wrong-endpoint` |
| 13 | The Silent Refund Worker | advanced | 250 | SNS filter policies, FilterPolicyScope, message attributes vs message body | `level-13-filter-policy-blocks-all` |
| 14 | Gift Wrap | advanced | 250 | SNS message envelope, RawMessageDelivery, subscription filter policy | `level-14-raw-delivery-missing` |
| 15 | Forty Tonnes of Paperwork | advanced | 300 | SQS message size limit, claim-check pattern, S3 offload | `level-15-message-too-large` |
| 16 | Mail Without a Stamp | advanced | 250 | IAM identity policy for SQS, least privilege, queue ARN | `level-16-producer-lacks-send` |
| 17 | Second Chance for Six Invoices | advanced | 300 | DLQ redrive, StartMessageMoveTask, operational recovery | `level-17-replay-the-dlq` |

## Module 6: CloudWatch & Logging (17 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | Logs Into the Void | beginner | 75 | CloudWatch Logs, log groups, log streams | `level-1-log-group-missing` |
| 2 | The Logs That Never Die | beginner | 100 | log retention, cost control, CloudWatch Logs groups | `level-2-retention-not-set` |
| 3 | Gateway Seven Is Mute | beginner | 100 | log streams, PutLogEvents, CloudWatch Logs hierarchy | `level-3-log-stream-missing` |
| 4 | Counting the Wrong Word | intermediate | 150 | metric filters, filter pattern syntax, logs to metrics | `level-4-metric-filter-wrong-pattern` |
| 5 | Nobody Is Watching Checkout | intermediate | 150 | CloudWatch alarms, alarm actions, SNS notifications | `level-5-alarm-missing` |
| 6 | A Zero Too Many | beginner | 100 | alarm thresholds, metric units and ranges, put-metric-alarm | `level-6-alarm-wrong-threshold` |
| 7 | The Pager That Never Rang | intermediate | 175 | alarm actions, ActionsEnabled, SNS topic subscriptions | `level-7-alarm-no-action` |
| 8 | Crying Wolf at Full Health | intermediate | 150 | comparison operators, alarm direction, metric dimensions | `level-8-alarm-wrong-comparison` |
| 9 | Five Minutes Too Late | intermediate | 175 | alarm period, detection latency, evaluation periods | `level-9-alarm-wrong-period` |
| 10 | The Empty Error Table | intermediate | 200 | Logs Insights, query syntax, JSON field discovery, CloudWatch dashboards | `level-10-log-insights-syntax` |
| 11 | Receipts on Strike | beginner | 100 | EventBridge rules, rule state, event delivery to SQS | `level-11-event-rule-disabled` |
| 12 | Shipment Sent to the Sandbox | intermediate | 150 | EventBridge targets, put-targets and remove-targets, environment isolation | `level-12-event-rule-wrong-target` |
| 13 | The Pattern That Matched Nothing | advanced | 225 | EventBridge event patterns, exact matching, content filtering on detail | `level-13-event-pattern-wrong` |
| 14 | Paging When Everything Is Fine | advanced | 300 | composite alarms, alarm rule expressions, boolean logic | `level-14-composite-alarm-inverted` |
| 15 | The Shipper Without a Ticket | advanced | 250 | IAM for CloudWatch Logs, logs:PutLogEvents, least privilege | `level-15-missing-iam-for-logs` |
| 16 | The Grey Light | intermediate | 200 | TreatMissingData, INSUFFICIENT_DATA state, sparse metrics | `level-16-alarm-stuck-insufficient-data` |
| 17 | Last Night's Outage Was Silent | expert | 450 | logs to metrics to alarms, metric filter patterns, metric namespaces, end-to-end verification | `level-17-logs-to-pager-pipeline` |

## Module 7: EC2 & Networking (17 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | Launch Day Lockout | beginner | 100 | security groups, RunInstances, VPC scoping | `level-1-sg-missing` |
| 2 | Quillpad Is Unreachable | beginner | 100 | security group inbound rules, default deny | `level-2-sg-no-inbound` |
| 3 | Eight-Thousand-Eighty Is Not Home | beginner | 100 | security group ports, source security groups, Parameter Store | `level-3-sg-wrong-port` |
| 4 | The Office Moved | beginner | 100 | CIDR notation, security group sources | `level-4-sg-wrong-cidr` |
| 5 | Hardened Into a Corner | beginner | 125 | security group egress, least privilege, default allow-all outbound | `level-5-sg-egress-blocked` |
| 6 | Room for Meridian | beginner | 125 | VPC CIDR planning, overlapping address space, VPC attributes | `level-6-vpc-missing` |
| 7 | An ALB With Nowhere to Land | beginner | 125 | subnets, availability zones, multi-AZ load balancers | `level-7-subnet-missing` |
| 8 | Skyline Café Is Offline | intermediate | 150 | internet gateway attachment, route targets, public subnets | `level-8-igw-not-attached` |
| 9 | Dead End Street | intermediate | 150 | route tables, main route table, public vs private subnets | `level-9-route-table-missing` |
| 10 | Wired to the Wrong Subnet | intermediate | 150 | route table associations, subnet isolation | `level-10-subnet-not-associated` |
| 11 | The Rule Before the Rule | intermediate | 200 | network ACL rule ordering, stateless filtering, ephemeral ports | `level-11-nacl-blocking-http` |
| 12 | Born Without Credentials | intermediate | 200 | instance profiles, role trust policy, least privilege | `level-12-iam-instance-profile-missing` |
| 13 | No Key, No Entry | intermediate | 200 | EC2 key pairs, immutable launch parameters, instance replacement | `level-13-key-pair-missing` |
| 14 | Invisible Instance | intermediate | 175 | public IPv4 addresses, Elastic IPs, auto-assign public IP | `level-14-public-ip-disabled` |
| 15 | Gossip Behind Closed Doors | advanced | 275 | self-referencing security groups, east-west traffic, TCP vs UDP rules | `level-15-sg-missing-self-reference` |
| 16 | Peering Without a Path | advanced | 300 | VPC peering, bidirectional routing, non-transitive networking | `level-16-peering-missing-routes` |
| 17 | Private Road to S3 | expert | 400 | VPC gateway endpoints, endpoint policies, private subnets | `level-17-s3-endpoint-missing` |

## Module 8: CloudFormation (18 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | Parse Error | beginner | 75 | CloudFormation template format, YAML indentation, create-stack | `level-1-yaml-syntax` |
| 2 | Green Stack, Missing Bucket | beginner | 100 | CloudFormation resource types, update-stack, describe-stack-resources | `level-2-wrong-resource-type` |
| 3 | Nobody Can Wear This Role | beginner | 125 | AWS::IAM::Role, AssumeRolePolicyDocument, required properties | `level-3-missing-required-property` |
| 4 | Who Fills the Blank? | beginner | 100 | CloudFormation parameters, Default values, create-stack --parameters | `level-4-parameter-no-default` |
| 5 | Thirty Seconds, Give or Take an S | intermediate | 150 | Number parameters, ROLLBACK_COMPLETE, stack events | `level-5-parameter-wrong-type` |
| 6 | Ref to Nowhere | intermediate | 150 | Ref intrinsic function, logical IDs, SSM parameters from CloudFormation | `level-6-ref-nonexistent` |
| 7 | Attribute Not Found | intermediate | 175 | Fn::GetAtt, resource attributes, UPDATE_ROLLBACK_COMPLETE | `level-7-getatt-wrong-attribute` |
| 8 | Chicken, Egg, Bucket | intermediate | 200 | circular dependencies, DependsOn, implicit dependencies via GetAtt and Ref | `level-8-circular-dependency` |
| 9 | Stack Stuck in Rollback | intermediate | 175 | ROLLBACK_COMPLETE, stack lifecycle, delete-stack, ImportValue | `level-9-rollback-complete` |
| 10 | Name Taken | intermediate | 200 | stack Outputs, Export names, cross-stack references | `level-10-output-export-duplicate` |
| 11 | No Export Named That | intermediate | 175 | Fn::ImportValue, list-exports, cross-stack references | `level-11-importvalue-wrong-name` |
| 12 | Upside-Down Production | advanced | 275 | Conditions, Fn::If, Fn::Equals, UsePreviousValue | `level-12-condition-inverted` |
| 13 | Handle With Care | advanced | 300 | DeletionPolicy, Retain, stack deletion, data safety | `level-13-deletion-policy-delete` |
| 14 | Policy Lock | intermediate | 200 | termination protection, stack protection, stack policies | `level-14-stack-policy-blocks` |
| 15 | Missing Map Entry | advanced | 250 | Mappings, Fn::FindInMap, pseudo parameters | `level-15-mapping-wrong-key` |
| 16 | SAM Template Rejected | advanced | 275 | CloudFormation Transform, AWS SAM, macros | `level-16-transform-missing` |
| 17 | Reality Diverged | expert | 450 | configuration drift, get-template, update-stack, infrastructure as code discipline | `level-17-stack-drift` |
| 18 | Nested Stack 404 | expert | 400 | nested stacks, TemplateURL, child stack parameters and outputs, Fn::GetAtt on stack outputs | `level-18-nested-stack-wrong-url` |

## Module 9: Secrets & Config (15 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | No Key | beginner | 100 | KMS keys, key aliases, automatic key rotation | `level-1-kms-key-missing` |
| 2 | Disabled Key | beginner | 100 | KMS key states, DisabledException, alias to key mapping | `level-2-kms-key-disabled` |
| 3 | No Key Permission | intermediate | 175 | KMS key policies, IAM policies vs key policies, least privilege | `level-3-kms-key-policy-missing` |
| 4 | Wrong Key Name | intermediate | 175 | KMS aliases, update-alias, key identification | `level-4-kms-wrong-alias` |
| 5 | No Secret | beginner | 100 | Secrets Manager deletion, recovery window, restore-secret | `level-5-secret-missing` |
| 6 | Wrong Key in JSON | intermediate | 175 | Secrets Manager JSON secrets, secret versions, put-secret-value | `level-6-secret-wrong-key` |
| 7 | Access Denied to Secret | intermediate | 200 | secretsmanager:GetSecretValue, secret ARNs, least privilege | `level-7-secret-no-permission` |
| 8 | Wrong Version | intermediate | 200 | secret versions, staging labels, AWSCURRENT / AWSPREVIOUS | `level-8-secret-wrong-version` |
| 9 | Stale Credentials | advanced | 275 | Secrets Manager rotation, rotation Lambda, rotation rules | `level-9-secret-rotation-broken` |
| 10 | Missing Config | beginner | 125 | SSM Parameter Store, put-parameter, parameter hierarchies | `level-10-ssm-parameter-missing` |
| 11 | Plaintext Secret | intermediate | 175 | SecureString, parameter types, KMS keys for SSM, parameter versions | `level-11-ssm-wrong-type` |
| 12 | Path Confusion | intermediate | 200 | Parameter Store hierarchies, parameter naming, path-scoped IAM | `level-12-ssm-wrong-path` |
| 13 | SSM Blocked | advanced | 250 | ssm:GetParameter, parameter ARNs, kms:Decrypt for SecureString, least privilege | `level-13-ssm-no-permission` |
| 14 | Rotation Breaks Decrypt | expert | 450 | manual vs automatic key rotation, kms:ReEncrypt, encryption context, key lifecycle | `level-14-kms-key-rotation` |
| 15 | Credentials in Code | expert | 400 | Lambda execution roles, credential hygiene, least privilege, access key deactivation | `level-15-hardcoded-credentials` |

## Module 10: ECS & Containers (16 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | The Cluster That Never Was | beginner | 100 | ECS clusters, run-task, Fargate | `level-1-cluster-missing` |
| 2 | Deployed Nothing | beginner | 100 | task definitions, register-task-definition, ECS services | `level-2-task-definition-missing` |
| 3 | Sizing the Thumbnailer | beginner | 125 | Fargate CPU and memory combinations, container memory limits, right-sizing | `level-3-wrong-cpu-memory` |
| 4 | Nobody to Pull the Secret | intermediate | 225 | task execution role, ECS trust policy, Secrets Manager access | `level-4-execution-role-missing` |
| 5 | Access Denied at the Bucket | intermediate | 225 | ECS task role, S3 bucket vs object ARNs, least privilege | `level-5-task-role-wrong-perms` |
| 6 | The Image That Wasn't There | intermediate | 150 | image references, stoppedReason, registry pulls | `level-6-ecr-image-missing` |
| 7 | Knocking on the Wrong Door | intermediate | 225 | containerPort, target groups, ECS load balancer mapping | `level-7-container-port-wrong` |
| 8 | Paused for Maintenance, Never Resumed | beginner | 75 | desiredCount, ECS services, capacity | `level-8-service-desired-zero` |
| 9 | Crash on Arrival | intermediate | 175 | container environment variables, task logs, exit codes | `level-9-env-var-missing` |
| 10 | Secret Handshake Failed | intermediate | 225 | ECS secrets, Secrets Manager ARNs, JSON key references | `level-10-secrets-wrong-arn` |
| 11 | Permanently Unhealthy | intermediate | 175 | target group health checks, response code matcher, load balancer reasons | `level-11-health-check-wrong` |
| 12 | Silent Checkout | intermediate | 200 | awslogs log driver, Fargate logging, CloudWatch Logs | `level-12-log-driver-wrong` |
| 13 | Private but Stranded | advanced | 300 | NAT gateway, private subnets, egress-only access | `level-13-subnet-no-nat` |
| 14 | Locked Out of Our Own Endpoints | advanced | 350 | security group egress and ingress pairing, interface VPC endpoints, isolated subnets | `level-14-sg-no-outbound` |
| 15 | Who Is inventory.shop.local? | advanced | 350 | AWS Cloud Map, ECS service discovery, private DNS namespaces | `level-15-service-discovery-missing` |
| 16 | Friday Deploy Gone Wrong | expert | 450 | task definition revisions, rollbacks, deployment circuit breaker | `level-16-bad-deployment-rollback` |

## Module 11: API Gateway (15 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | Status Page With No Page | beginner | 100 | REST API building blocks, Lambda proxy integration, deployment and stages | `level-1-api-missing` |
| 2 | Notes Without an Address | beginner | 110 | API resources, path parameters, redeploying a stage | `level-2-resource-missing` |
| 3 | Read-Only by Accident | beginner | 115 | HTTP methods on a resource, one integration per method, Lambda proxy request body | `level-3-method-wrong` |
| 4 | A Door Into an Empty Room | beginner | 120 | method vs integration, Lambda proxy integration, query string parameters | `level-4-integration-missing` |
| 5 | Dial the Right Number | beginner | 125 | integration URI, Lambda ARN, updating an integration in place | `level-5-integration-wrong-arn` |
| 6 | Locked Out After the Rebuild | intermediate | 175 | Lambda resource-based policy, lambda add-permission, source ARN scoping | `level-6-lambda-permission-missing` |
| 7 | Ready, Tested, Invisible | beginner | 125 | deployments, stages, stage variables | `level-7-not-deployed` |
| 8 | The Browser Says No | intermediate | 225 | CORS preflight, MOCK integration, integration response header mapping | `level-8-cors-missing` |
| 9 | Zero Tolerance | advanced | 275 | stage throttling, method settings, rate vs burst | `level-9-throttle-zero` |
| 10 | Token in the Wrong Pocket | advanced | 250 | Lambda authorizer (TOKEN), identity source, 401 vs 403 | `level-10-auth-wrong` |
| 11 | Lost in Translation | advanced | 325 | VTL mapping templates, $input.path, escapeJavaScript, non-proxy integration | `level-11-mapping-template-wrong` |
| 12 | A Key to Nowhere | advanced | 325 | API keys, usage plans, stage association, quota and throttle | `level-12-api-key-no-plan` |
| 13 | One Setting for the Whole Browser | advanced | 275 | HTTP API (v2), CorsConfiguration, credentials and wildcard origins | `level-13-http-api-cors` |
| 14 | Yes Means Yes | advanced | 300 | HTTP API Lambda authorizer, simple responses vs IAM policy responses, authorizer payload format | `level-14-http-api-authorizer` |
| 15 | Two Dialects of the Same Event | advanced | 250 | HTTP API payload format version, event shape 1.0 vs 2.0, automatic response formatting | `level-15-http-api-payload-format` |

## Module 12: Step Functions (14 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | Nobody Invited the Lambda | beginner | 90 | Step Functions execution role, lambda:InvokeFunction, least privilege | `level-1-invoke-denied` |
| 2 | Ghost Function | beginner | 100 | Task state Resource ARN, Lambda.ResourceNotFoundException, update-state-machine | `level-2-renamed-function` |
| 3 | Fell Through the Cracks | beginner | 90 | Choice state, Default branch, States.Runtime errors | `level-3-no-default-route` |
| 4 | Where Did My Order Go | beginner | 100 | ResultPath, state input and output, JSONPath | `level-4-input-overwritten` |
| 5 | Literally Dollar | intermediate | 150 | Parameters, dynamic values with .$, intrinsic functions, States.Format | `level-5-literal-dollar` |
| 6 | Truthy Parcels | intermediate | 160 | Choice state, BooleanEquals, IsPresent, JSON types | `level-6-boolean-as-text` |
| 7 | Try, Try Again | intermediate | 180 | Retry, ErrorEquals, transient versus permanent errors, BackoffRate | `level-7-retry-wrong-errors` |
| 8 | Silent Failure | intermediate | 200 | Catch, error handling, Fail state, ResultPath on Catch | `level-8-swallowed-error` |
| 9 | A Week Is Not Always a Week | intermediate | 170 | Wait state, Timestamp / TimestampPath, long-running executions | `level-9-wait-forever` |
| 10 | Two Branches, One Array | advanced | 280 | Parallel state, ResultSelector, ResultPath, state data flow | `level-10-parallel-array` |
| 11 | One Bad Parcel | advanced | 310 | Map state, ItemSelector, per-item Catch, partial failure | `level-11-poison-parcel` |
| 12 | The Approver Never Called Back | advanced | 330 | waitForTaskToken, send-task-success / send-task-failure, callback pattern, Catch | `level-12-approval-token` |
| 13 | Friday Release | expert | 520 | state machine versions, aliases, rollback and fix-forward, Choice thresholds | `level-13-bad-release-alias` |
| 14 | Four Dominoes | expert | 560 | EventBridge rules, event patterns, Step Functions as a rule target, input path, execution role | `level-14-event-to-workflow` |

## Module 13: Cognito (14 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | Door Without a Handle | beginner | 90 | app client auth flows, USER_PASSWORD_AUTH, ExplicitAuthFlows | `level-1-auth-flow-off` |
| 2 | Twenty-Four Characters of Pain | beginner | 100 | password policy, InvalidPasswordException, user pool configuration | `level-2-password-too-strict` |
| 3 | Welcome Aboard, Please Wait | beginner | 90 | FORCE_CHANGE_PASSWORD, NEW_PASSWORD_REQUIRED challenge, admin-set-user-password | `level-3-stuck-on-temp-password` |
| 4 | Check Your Inbox | beginner | 100 | sign-up confirmation, UNCONFIRMED users, email verification | `level-4-unconfirmed-signup` |
| 5 | Never Ship a Secret | intermediate | 150 | client secret, SECRET_HASH, public vs confidential clients | `level-5-secret-in-the-binary` |
| 6 | Reset Goes Nowhere | intermediate | 170 | forgot-password flow, email_verified, account recovery | `level-6-reset-goes-nowhere` |
| 7 | Admin in Name Only | intermediate | 160 | user pool groups, cognito:groups claim, group membership | `level-7-missing-admin-group` |
| 8 | One Flag Too Few | intermediate | 200 | update-user-pool-client replaces settings, token validity, hosted UI callback URLs | `level-8-client-update-wipe` |
| 9 | Provisioner Denied | intermediate | 200 | IAM permissions for Cognito admin APIs, user pool ARN, least privilege | `level-9-provisioner-denied` |
| 10 | Read-Only Robot | advanced | 300 | resource servers and custom scopes, client credentials grant, allowed OAuth scopes | `level-10-machine-scopes` |
| 11 | Lost in Redirect | advanced | 300 | hosted UI, callback URL matching, OAuth authorization code flow | `level-11-hosted-ui-redirect` |
| 12 | The Bouncer Who Forgot to Answer | advanced | 300 | Lambda triggers, pre sign-up, trigger response contract | `level-12-presignup-trigger` |
| 13 | Claims Vanish | expert | 500 | pre token generation trigger, Lambda config is replaced as a whole, custom attributes and claims | `level-13-claims-vanish` |
| 14 | Stolen Session | expert | 550 | incident response, global sign-out, token revocation, password reset | `level-14-stolen-session` |

## Module 14: Load Balancing & Auto Scaling (14 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | Ghost Town Storefront | beginner | 80 | target groups, register targets, ALB 503 | `level-1-empty-target-group` |
| 2 | Right Address, Wrong Extension | beginner | 90 | target port override, deregister-targets, target health | `level-2-wrong-target-port` |
| 3 | Taking the Pulse | beginner | 100 | health checks, health check path, success codes matcher | `level-3-health-check-path` |
| 4 | Members Meet the Staging Build | beginner | 100 | listeners, default actions, forward to target group | `level-4-listener-wrong-target-group` |
| 5 | Admin Door Left Ajar | intermediate | 160 | listener rules, rule priority, path-pattern conditions, fixed-response action | `level-5-rule-priority-shadow` |
| 6 | One Letter Off | intermediate | 170 | host-header conditions, listener rules, virtual hosting | `level-6-host-header-typo` |
| 7 | Secure by Redirect | intermediate | 175 | redirect action, HTTP 301 vs 302, redirect placeholders | `level-7-https-redirect` |
| 8 | Cart Amnesia | intermediate | 180 | sticky sessions, lb_cookie, target group attributes | `level-8-sticky-sessions` |
| 9 | The Night Shift Never Ended | intermediate | 190 | Auto Scaling min/desired/max, scheduled actions, capacity | `level-9-asg-scaled-to-zero` |
| 10 | Orphaned Fleet | advanced | 260 | Auto Scaling + load balancer integration, attach target groups, self-healing | `level-10-asg-not-attached` |
| 11 | Version One Forever | advanced | 280 | launch template versions, instance refresh, ASG launch template reference | `level-11-stale-launch-template` |
| 12 | Out of Breath | advanced | 300 | health check timeout and interval, failure detection time, Target.Timeout | `level-12-health-check-timeout` |
| 13 | Cutover Night | expert | 480 | weighted target groups, blue/green deployment, capacity before traffic | `level-13-blue-green-cutover` |
| 14 | Internal Affairs | expert | 520 | internal vs internet-facing, immutable load balancer scheme, rebuilding listeners and rules | `level-14-internal-alb-migration` |

## Module 15: Kinesis & Firehose (14 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | Wrong Stream, Right Thermostat | beginner | 75 | Kinesis stream names, Lambda environment variables, ResourceNotFoundException | `level-1-stream-name-typo` |
| 2 | Scan and Deliver Denied | beginner | 100 | Kinesis IAM actions, stream ARNs, least privilege | `level-2-scanner-denied` |
| 3 | Short Memory | beginner | 100 | stream retention period, replay, Kinesis cost model | `level-3-short-memory` |
| 4 | The Auditor Sees Nothing | beginner | 125 | shard iterator types, TRIM_HORIZON vs LATEST, GetRecords | `level-4-audit-sees-nothing` |
| 5 | One Key to Rule Them All | intermediate | 150 | partition keys, hot shards, ordering within a shard | `level-5-one-key-to-rule-them-all` |
| 6 | Ceiling at One Megabyte | intermediate | 175 | shard capacity, resharding, UpdateShardCount | `level-6-single-shard-ceiling` |
| 7 | Sharing the Pipe | intermediate | 200 | enhanced fan-out, stream consumers, event source mappings | `level-7-shared-pipe` |
| 8 | Billed Twice at the Seam | intermediate | 175 | AT_SEQUENCE_NUMBER vs AFTER_SEQUENCE_NUMBER, consumer checkpoints, at-least-once processing | `level-8-billed-twice` |
| 9 | Poison Pill in the Pipe | intermediate | 225 | event source mapping error handling, bisect batch on function error, maximum retry attempts, on-failure destination | `level-9-poison-pill` |
| 10 | Clicks in the Wrong Lake | advanced | 250 | Firehose S3 destination, UpdateDestination, custom prefixes, delivery stream versions | `level-10-clicks-in-the-wrong-lake` |
| 11 | Fifteen Minutes Too Late | advanced | 275 | Firehose buffering hints, buffer size vs interval, compression, small-files problem | `level-11-fifteen-minutes-late` |
| 12 | The Archive That Never Fills | advanced | 325 | Firehose sources, KinesisStreamAsSource, immutable delivery stream type | `level-12-archive-that-never-fills` |
| 13 | Breaking the Transform Contract | expert | 450 | Firehose data transformation, recordId, result and data contract, base64 payloads, processing-failed records | `level-13-transform-contract` |
| 14 | Orphaned Parents, Missing Children | expert | 550 | resharding, parent and child shards, ListShards, ordering across shards | `level-14-orphaned-parents` |

## Module 16: Production War Games (20 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | The Blocked Pipeline | expert | 400 | identity vs resource policies, explicit Deny, Lambda configuration, incident triage | `level-1-lambda-cant-read-s3` |
| 2 | The Silent Chain | expert | 450 | SNS subscription filter policies, raw message delivery, SQS event source mappings, Lambda reserved concurrency | `level-2-sns-sqs-lambda-broken` |
| 3 | The Blind System | expert | 450 | CloudWatch Logs metric filters, alarm comparison operators, alarm actions, SNS to SQS paging | `level-3-alarm-never-fires` |
| 4 | Upload Goes Nowhere | expert | 450 | S3 event notifications, notification key filters, Lambda execution role, recursive trigger risk | `level-4-s3-trigger-broken` |
| 5 | The Dead API | expert | 500 | API Gateway stages and deployments, Lambda proxy integration, usage plans and API keys, Lambda reserved concurrency | `level-5-api-gateway-full-break` |
| 6 | Container Chaos | expert | 500 | ECS task definitions, container startup failures, ECS services and desired count, stopped task diagnostics | `level-6-ecs-wont-start` |
| 7 | Stream Silence | expert | 475 | DynamoDB Streams, stream view types, event source mappings, Lambda environment and IAM | `level-7-dynamodb-lambda-stream` |
| 8 | Stack Refuses to Update | expert | 475 | CloudFormation failed stacks, export name uniqueness, DeletionPolicy Retain, Lambda handler configuration | `level-8-cfn-stack-broken` |
| 9 | The Credential Crisis | expert | 500 | Secrets Manager ARNs and version stages, rotation failure recovery, IAM resource scoping for secrets, Lambda configuration | `level-9-secrets-rotation-cascade` |
| 10 | The Missing Bridge | expert | 500 | cross-account role assumption, ExternalId and confused deputy, role chaining, trust policy vs identity policy | `level-10-cross-account-role` |
| 11 | Security Audit | expert | 550 | IAM privilege escalation paths, iam:PassRole scoping, least privilege, resource-level permissions | `level-11-iam-privilege-escalation` |
| 12 | Data Exposure Incident | expert | 550 | S3 bucket policies and public principals, IAM group and user policies, prefix-scoped least privilege, incident containment without outage | `level-12-public-s3-exposure` |
| 13 | Queue Meltdown | expert | 475 | SQS dead-letter queues and redrive policy, maxReceiveCount, visibility timeout, CloudWatch alarms on SQS metrics | `level-13-sqs-message-pileup` |
| 14 | Flying Blind | expert | 500 | CloudWatch Logs metric filters (JSON patterns), Lambda log groups, alarm metric matching, SNS paging topology | `level-14-cloudwatch-observability-gap` |
| 15 | The Unreachable Service | expert | 550 | private subnets and NAT gateways, route tables, security group ingress and egress, ECS awsvpc networking | `level-15-ecs-networking-labyrinth` |
| 16 | Encryption Lockout | expert | 550 | KMS key states, pending deletion and cancel-key-deletion, KMS aliases, key-scoped IAM permissions, key rotation | `level-16-kms-breaks-everything` |
| 17 | The Auth Maze | expert | 575 | API Gateway Lambda authorizers, authorization types, identity source, Lambda execution roles, stage deployments | `level-17-api-auth-lockout` |
| 18 | The Production Incident | expert | 600 | end-to-end incident triage, Lambda environment configuration, IAM resource scoping for SQS, reserved concurrency, DynamoDB key schema | `level-18-full-stack-incident` |
| 19 | Leaked Keys | expert | 550 | credential leak response, access key rotation, attacker persistence, least privilege | `level-19-leaked-credential-response` |
| 20 | Total Recall | expert | 550 | S3 versioning and delete markers, restoring previous object versions, DynamoDB point-in-time recovery, preventing destructive actions | `level-20-data-loss-recovery` |
