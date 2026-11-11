# AWSMissions Curriculum

Generated from each level's `mission.yaml` by `scripts/build_levels.py`. Do not edit by hand.

**196 missions across 12 modules.**

## Module 1: IAM Foundations (20 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | The Empty Statement | beginner | 100 | IAM inline policies, s3:GetObject, least privilege | `level-1-empty-policy` |
| 2 | Wrong Side of the Law | beginner | 100 | IAM policy evaluation, explicit Deny, s3:PutObject | `level-2-deny-effect` |
| 3 | The Misspelled Gate | beginner | 100 | IAM, roles, policies, policy debugging | `level-3-action-typo` |
| 4 | The Locked Vault | beginner | 125 | IAM, roles, policies, policy debugging, buckets | `level-4-wrong-resource` |
| 5 | The Bare Role | beginner | 125 | IAM, roles, policies, policy debugging, lambda functions | `level-5-no-policy` |
| 6 | Trust Nobody | beginner | 150 | IAM, roles, policies, policy debugging | `level-6-wrong-principal` |
| 7 | Wrong Service | beginner | 150 | IAM, roles, policies, policy debugging, lambda functions | `level-7-wrong-service-principal` |
| 8 | The Blocked Handoff | beginner | 175 | IAM, roles, policies, policy debugging, lambda functions | `level-8-missing-passrole` |
| 9 | The Orphan User | beginner | 125 | IAM, roles, policies, policy debugging | `level-9-user-no-group` |
| 10 | The Empty Club | beginner | 125 | IAM, roles, policies, policy debugging | `level-10-group-no-policy` |
| 11 | The Bad Condition | beginner | 175 | IAM, roles, policies, policy debugging | `level-11-condition-wrong-key` |
| 12 | Almost Right | beginner | 175 | IAM, roles, policies, policy debugging | `level-12-condition-operator` |
| 13 | Time Traveler | beginner | 125 | IAM, roles, policies, policy debugging | `level-13-policy-missing-version` |
| 14 | Double Trouble | beginner | 200 | IAM, roles, policies, policy debugging | `level-14-inline-blocks-managed` |
| 15 | Can't Switch Hats | beginner | 150 | IAM, roles, policies, policy debugging | `level-15-assume-role-no-sts` |
| 16 | The Missing Secret Handshake | beginner | 200 | IAM, roles, policies, policy debugging, secrets | `level-16-external-id-missing` |
| 17 | The Invisible Ceiling | beginner | 225 | IAM, roles, policies, policy debugging | `level-17-permission-boundary` |
| 18 | Scope Creep | beginner | 125 | IAM, roles, policies, policy debugging, buckets | `level-18-resource-wildcard` |
| 19 | The Wrong Path | beginner | 175 | IAM, roles, policies, policy debugging | `level-19-path-mismatch` |
| 20 | The Bloated Policy | beginner | 200 | IAM, roles, policies, policy debugging | `level-20-policy-size` |

## Module 2: S3 Mastery (20 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | No Bucket, No Service | beginner | 100 | S3 bucket creation, aws s3 mb | `level-1-bucket-missing` |
| 2 | Keep Out | beginner | 125 | S3, bucket configuration, object access, policy debugging, buckets | `level-2-access-denied-read` |
| 3 | Read-Only Trap | beginner | 125 | S3, bucket configuration, object access, policy debugging, buckets | `level-3-access-denied-write` |
| 4 | Lost History | beginner | 125 | S3, bucket configuration, object access, buckets, REST APIs | `level-4-versioning-disabled` |
| 5 | Frozen in Time | beginner | 150 | S3, bucket configuration, object access | `level-5-versioning-suspended` |
| 6 | The Force Field | beginner | 150 | S3, bucket configuration, object access, policy debugging, buckets | `level-6-public-access-block` |
| 7 | The CORS Complaint | beginner | 150 | S3, bucket configuration, object access, buckets, REST APIs | `level-7-cors-missing` |
| 8 | Wrong Domain Allowed | beginner | 150 | S3, bucket configuration, object access | `level-8-cors-wrong-origin` |
| 9 | Eternal Storage | beginner | 175 | S3, bucket configuration, object access | `level-9-lifecycle-wrong-prefix` |
| 10 | Incomplete Uploads Pile Up | beginner | 175 | S3, bucket configuration, object access | `level-10-lifecycle-missing` |
| 11 | Silent Arrivals | beginner | 175 | S3, bucket configuration, object access, buckets, lambda functions | `level-11-notification-missing` |
| 12 | Wrong Trigger | beginner | 150 | S3, bucket configuration, object access | `level-12-notification-wrong-event` |
| 13 | Plaintext Exposure | beginner | 150 | S3, bucket configuration, object access, buckets, REST APIs | `level-13-encryption-missing` |
| 14 | The Broken Gate | beginner | 125 | S3, bucket configuration, object access, policy debugging, buckets | `level-14-bucket-policy-syntax` |
| 15 | Public by Accident | beginner | 125 | S3, bucket configuration, object access, buckets, REST APIs | `level-15-acl-too-open` |
| 16 | Silent Website | beginner | 150 | S3, bucket configuration, object access | `level-16-static-website-missing` |
| 17 | No Paper Trail | beginner | 150 | S3, bucket configuration, object access, buckets, REST APIs | `level-17-logging-disabled` |
| 18 | Too Flexible | beginner | 200 | S3, bucket configuration, object access | `level-18-object-lock-wrong-mode` |
| 19 | Expensive Archive | beginner | 175 | S3, bucket configuration, object access | `level-19-wrong-storage-class` |
| 20 | Unexpected Bills | beginner | 175 | S3, bucket configuration, object access, buckets, REST APIs | `level-20-requester-pays-wrong` |

## Module 3: Lambda Functions (18 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | No Function Found | beginner | 100 | Lambda, execution roles, function configuration, lambda functions | `level-1-function-missing` |
| 2 | Deprecated Engine | beginner | 125 | Lambda, execution roles, function configuration, lambda functions | `level-2-wrong-runtime` |
| 3 | The Missing Door | beginner | 125 | Lambda, execution roles, function configuration, lambda functions | `level-3-handler-wrong` |
| 4 | The Roleless Function | beginner | 150 | Lambda, execution roles, function configuration, policy debugging, roles | `level-4-role-missing` |
| 5 | Wrong Trust | beginner | 150 | Lambda, execution roles, function configuration, policy debugging, roles | `level-5-role-wrong-service` |
| 6 | The Blank Config | beginner | 125 | Lambda, execution roles, function configuration, lambda functions | `level-6-env-var-missing` |
| 7 | Three Seconds and Out | beginner | 125 | Lambda, execution roles, function configuration, lambda functions | `level-7-timeout-too-low` |
| 8 | Out of Memory | beginner | 125 | Lambda, execution roles, function configuration, lambda functions | `level-8-memory-too-low` |
| 9 | The Throttled Function | beginner | 150 | Lambda, execution roles, function configuration, lambda functions | `level-9-concurrency-zero` |
| 10 | Lost on Failure | beginner | 175 | Lambda, execution roles, function configuration, lambda functions, queues | `level-10-dlq-missing` |
| 11 | Missing Dependency | beginner | 200 | Lambda, execution roles, function configuration, lambda functions | `level-11-layer-wrong-arn` |
| 12 | The Silent Upload | beginner | 175 | Lambda, execution roles, function configuration, buckets, lambda functions | `level-12-trigger-missing` |
| 13 | Watching the Wrong Door | beginner | 150 | Lambda, execution roles, function configuration, buckets | `level-13-trigger-wrong-bucket` |
| 14 | Permission Denied by Lambda | beginner | 200 | Lambda, execution roles, function configuration, policy debugging, lambda functions | `level-14-resource-policy-missing` |
| 15 | The Ghost Alias | beginner | 175 | Lambda, execution roles, function configuration, lambda functions | `level-15-alias-wrong-version` |
| 16 | Stranded in VPC | beginner | 175 | Lambda, execution roles, function configuration, lambda functions, VPCs | `level-16-vpc-no-subnet` |
| 17 | Unguarded VPC | beginner | 175 | Lambda, execution roles, function configuration, lambda functions, VPCs | `level-17-vpc-no-sg` |
| 18 | The Locked Door | beginner | 150 | Lambda, execution roles, function configuration, lambda functions | `level-18-function-url-auth` |

## Module 4: DynamoDB (15 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | No Table, No Data | intermediate | 150 | DynamoDB, tables, indexes | `level-1-table-missing` |
| 2 | Type Mismatch | intermediate | 200 | DynamoDB, tables, indexes | `level-2-wrong-key-type` |
| 3 | One Key Short | intermediate | 200 | DynamoDB, tables, indexes | `level-3-missing-sort-key` |
| 4 | No Index, No Query | intermediate | 250 | DynamoDB, tables, indexes | `level-4-gsi-missing` |
| 5 | Wrong Index Key | intermediate | 250 | DynamoDB, tables, indexes | `level-5-gsi-wrong-key` |
| 6 | Out of Capacity | intermediate | 200 | DynamoDB, tables, indexes | `level-6-capacity-throttle` |
| 7 | Provisionless Pain | intermediate | 200 | DynamoDB, tables, indexes | `level-7-billing-mode-wrong` |
| 8 | Eternal Records | intermediate | 175 | DynamoDB, tables, indexes | `level-8-ttl-disabled` |
| 9 | The Silent Table | intermediate | 225 | DynamoDB, tables, indexes, lambda functions, streams | `level-9-streams-disabled` |
| 10 | Local Index Gap | intermediate | 275 | DynamoDB, tables, indexes | `level-10-lsi-missing` |
| 11 | Half the Picture | intermediate | 250 | DynamoDB, tables, indexes | `level-11-projection-wrong` |
| 12 | No Safety Net | intermediate | 175 | DynamoDB, tables, indexes | `level-12-pitr-disabled` |
| 13 | The Overprotective Guard | intermediate | 250 | DynamoDB, tables, indexes | `level-13-condition-blocks-write` |
| 14 | Reserved Words | intermediate | 225 | DynamoDB, tables, indexes | `level-14-reserved-word-attr` |
| 15 | Full Table Scan | intermediate | 300 | DynamoDB, tables, indexes | `level-15-scan-instead-of-query` |

## Module 5: SQS & SNS (15 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | No Queue | intermediate | 150 | SQS, SNS, event delivery, queues | `level-1-queue-missing` |
| 2 | Wrong Address | intermediate | 150 | SQS, SNS, event delivery, queues | `level-2-wrong-queue-url` |
| 3 | Message Ghost | intermediate | 200 | SQS, SNS, event delivery, queues | `level-3-visibility-too-low` |
| 4 | No Safety Net | intermediate | 225 | SQS, SNS, event delivery, policy debugging, queues | `level-4-dlq-missing` |
| 5 | Lost DLQ | intermediate | 200 | SQS, SNS, event delivery, policy debugging, queues | `level-5-dlq-wrong-arn` |
| 6 | Zero Tolerance | intermediate | 175 | SQS, SNS, event delivery, policy debugging | `level-6-max-receive-zero` |
| 7 | Order Ignored | intermediate | 225 | SQS, SNS, event delivery, queues | `level-7-fifo-missing` |
| 8 | Duplicate Messages | intermediate | 200 | SQS, SNS, event delivery, queues | `level-8-fifo-no-deduplication` |
| 9 | SNS Can't Send | intermediate | 250 | SQS, SNS, event delivery, policy debugging, queues | `level-9-queue-policy-missing` |
| 10 | No Topic | intermediate | 150 | SQS, SNS, event delivery, topics | `level-10-topic-missing` |
| 11 | Topic, No Subscribers | intermediate | 175 | SQS, SNS, event delivery, queues, topics | `level-11-subscription-missing` |
| 12 | Wrong Endpoint | intermediate | 175 | SQS, SNS, event delivery, queues | `level-12-subscription-wrong-endpoint` |
| 13 | The Silence Filter | intermediate | 250 | SQS, SNS, event delivery, policy debugging | `level-13-filter-policy-blocks-all` |
| 14 | Double-Wrapped | intermediate | 225 | SQS, SNS, event delivery, lambda functions | `level-14-raw-delivery-missing` |
| 15 | Message Size Exceeded | intermediate | 300 | SQS, SNS, event delivery, queues | `level-15-message-too-large` |

## Module 6: CloudWatch & Logging (15 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | Where Are My Logs? | intermediate | 150 | CloudWatch, logs, alarms, lambda functions | `level-1-log-group-missing` |
| 2 | Infinite Log Growth | intermediate | 150 | CloudWatch, logs, alarms, policy debugging | `level-2-retention-not-set` |
| 3 | Stream Doesn't Exist | intermediate | 150 | CloudWatch, logs, alarms, streams | `level-3-log-stream-missing` |
| 4 | Filter Catches Nothing | intermediate | 200 | CloudWatch, logs, alarms | `level-4-metric-filter-wrong-pattern` |
| 5 | Silent Failure | intermediate | 200 | CloudWatch, logs, alarms | `level-5-alarm-missing` |
| 6 | Always Firing | intermediate | 175 | CloudWatch, logs, alarms | `level-6-alarm-wrong-threshold` |
| 7 | The Mute Alarm | intermediate | 200 | CloudWatch, logs, alarms, topics | `level-7-alarm-no-action` |
| 8 | Backwards Alarm | intermediate | 175 | CloudWatch, logs, alarms | `level-8-alarm-wrong-comparison` |
| 9 | Too Granular | intermediate | 200 | CloudWatch, logs, alarms | `level-9-alarm-wrong-period` |
| 10 | Query Crash | intermediate | 225 | CloudWatch, logs, alarms | `level-10-log-insights-syntax` |
| 11 | Rule Is Off | intermediate | 150 | CloudWatch, logs, alarms | `level-11-event-rule-disabled` |
| 12 | Wrong Destination | intermediate | 175 | CloudWatch, logs, alarms, lambda functions | `level-12-event-rule-wrong-target` |
| 13 | Mismatched Pattern | intermediate | 175 | CloudWatch, logs, alarms | `level-13-event-pattern-wrong` |
| 14 | Logic Flipped | intermediate | 275 | CloudWatch, logs, alarms | `level-14-composite-alarm-inverted` |
| 15 | No Permission to Write | intermediate | 225 | CloudWatch, logs, alarms, roles, lambda functions | `level-15-missing-iam-for-logs` |

## Module 7: EC2 & Networking (15 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | No Security Group | intermediate | 175 | EC2, VPC, networking, VPCs | `level-1-sg-missing` |
| 2 | The Closed Door | intermediate | 175 | EC2, VPC, networking | `level-2-sg-no-inbound` |
| 3 | Port Mismatch | intermediate | 175 | EC2, VPC, networking | `level-3-sg-wrong-port` |
| 4 | Too Restrictive CIDR | intermediate | 175 | EC2, VPC, networking | `level-4-sg-wrong-cidr` |
| 5 | No Way Out | intermediate | 200 | EC2, VPC, networking, REST APIs | `level-5-sg-egress-blocked` |
| 6 | No Network | intermediate | 200 | EC2, VPC, networking, VPCs | `level-6-vpc-missing` |
| 7 | No Subnets | intermediate | 225 | EC2, VPC, networking, VPCs, subnets | `level-7-subnet-missing` |
| 8 | Internet Gap | intermediate | 225 | EC2, VPC, networking, VPCs | `level-8-igw-not-attached` |
| 9 | No Route to Internet | intermediate | 250 | EC2, VPC, networking, VPCs, subnets | `level-9-route-table-missing` |
| 10 | Route Table Orphan | intermediate | 225 | EC2, VPC, networking, subnets, routing | `level-10-subnet-not-associated` |
| 11 | Firewall in the Way | intermediate | 275 | EC2, VPC, networking | `level-11-nacl-blocking-http` |
| 12 | EC2 Can't Talk to AWS | intermediate | 250 | EC2, VPC, networking, roles, REST APIs | `level-12-iam-instance-profile-missing` |
| 13 | No SSH Key | intermediate | 225 | EC2, VPC, networking | `level-13-key-pair-missing` |
| 14 | Invisible Instance | intermediate | 250 | EC2, VPC, networking, subnets | `level-14-public-ip-disabled` |
| 15 | Cluster Can't Talk | intermediate | 275 | EC2, VPC, networking | `level-15-sg-missing-self-reference` |

## Module 8: CloudFormation (18 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | Parse Error | intermediate | 150 | CloudFormation, stacks, templates | `level-1-yaml-syntax` |
| 2 | Unknown Resource | intermediate | 150 | CloudFormation, stacks, templates, buckets | `level-2-wrong-resource-type` |
| 3 | Missing Requirement | intermediate | 175 | CloudFormation, stacks, templates, policy debugging, roles | `level-3-missing-required-property` |
| 4 | No Default Value | intermediate | 175 | CloudFormation, stacks, templates, parameter store | `level-4-parameter-no-default` |
| 5 | Type Collision | intermediate | 175 | CloudFormation, stacks, templates, parameter store | `level-5-parameter-wrong-type` |
| 6 | Missing Reference | intermediate | 175 | CloudFormation, stacks, templates, buckets | `level-6-ref-nonexistent` |
| 7 | Wrong Attribute | intermediate | 200 | CloudFormation, stacks, templates | `level-7-getatt-wrong-attribute` |
| 8 | Going in Circles | intermediate | 275 | CloudFormation, stacks, templates | `level-8-circular-dependency` |
| 9 | Stack Stuck | intermediate | 200 | CloudFormation, stacks, templates | `level-9-rollback-complete` |
| 10 | Name Conflict | intermediate | 225 | CloudFormation, stacks, templates, buckets | `level-10-output-export-duplicate` |
| 11 | Broken Cross-Stack Link | intermediate | 200 | CloudFormation, stacks, templates, buckets | `level-11-importvalue-wrong-name` |
| 12 | Wrong Condition Logic | intermediate | 225 | CloudFormation, stacks, templates | `level-12-condition-inverted` |
| 13 | Dangerous Delete | intermediate | 200 | CloudFormation, stacks, templates, policy debugging, buckets | `level-13-deletion-policy-delete` |
| 14 | Policy Lock | intermediate | 250 | CloudFormation, stacks, templates, policy debugging, buckets | `level-14-stack-policy-blocks` |
| 15 | Missing Map Entry | intermediate | 200 | CloudFormation, stacks, templates | `level-15-mapping-wrong-key` |
| 16 | SAM Template Rejected | intermediate | 225 | CloudFormation, stacks, templates | `level-16-transform-missing` |
| 17 | Reality Diverged | intermediate | 300 | CloudFormation, stacks, templates | `level-17-stack-drift` |
| 18 | Nested Stack 404 | intermediate | 275 | CloudFormation, stacks, templates | `level-18-nested-stack-wrong-url` |

## Module 9: Secrets & Config (15 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | No Key | advanced | 250 | Secrets Manager, SSM, KMS | `level-1-kms-key-missing` |
| 2 | Disabled Key | advanced | 225 | Secrets Manager, SSM, KMS | `level-2-kms-key-disabled` |
| 3 | No Key Permission | advanced | 300 | Secrets Manager, SSM, KMS, policy debugging, roles | `level-3-kms-key-policy-missing` |
| 4 | Wrong Key Name | advanced | 225 | Secrets Manager, SSM, KMS | `level-4-kms-wrong-alias` |
| 5 | No Secret | advanced | 250 | Secrets Manager, SSM, KMS, secrets | `level-5-secret-missing` |
| 6 | Wrong Key in JSON | advanced | 250 | Secrets Manager, SSM, KMS, secrets | `level-6-secret-wrong-key` |
| 7 | Access Denied to Secret | advanced | 275 | Secrets Manager, SSM, KMS, policy debugging, roles | `level-7-secret-no-permission` |
| 8 | Wrong Version | advanced | 300 | Secrets Manager, SSM, KMS, secrets | `level-8-secret-wrong-version` |
| 9 | Stale Credentials | advanced | 325 | Secrets Manager, SSM, KMS, lambda functions, secrets | `level-9-secret-rotation-broken` |
| 10 | Missing Config | advanced | 225 | Secrets Manager, SSM, KMS, parameter store | `level-10-ssm-parameter-missing` |
| 11 | Plaintext Secret | advanced | 250 | Secrets Manager, SSM, KMS, secrets, parameter store | `level-11-ssm-wrong-type` |
| 12 | Path Confusion | advanced | 225 | Secrets Manager, SSM, KMS, parameter store | `level-12-ssm-wrong-path` |
| 13 | SSM Blocked | advanced | 275 | Secrets Manager, SSM, KMS, roles, parameter store | `level-13-ssm-no-permission` |
| 14 | Rotation Breaks Decrypt | advanced | 350 | Secrets Manager, SSM, KMS | `level-14-kms-key-rotation` |
| 15 | Credentials in Code | advanced | 375 | Secrets Manager, SSM, KMS, roles, lambda functions | `level-15-hardcoded-credentials` |

## Module 10: ECS & Containers (15 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | No Cluster | advanced | 225 | ECS, Fargate, task definitions | `level-1-cluster-missing` |
| 2 | No Task Definition | advanced | 250 | ECS, Fargate, task definitions, tasks | `level-2-task-definition-missing` |
| 3 | Invalid Config | advanced | 250 | ECS, Fargate, task definitions, tasks | `level-3-wrong-cpu-memory` |
| 4 | Can't Pull Image | advanced | 275 | ECS, Fargate, task definitions, policy debugging, roles | `level-4-execution-role-missing` |
| 5 | App Can't Access AWS | advanced | 275 | ECS, Fargate, task definitions, roles, tasks | `level-5-task-role-wrong-perms` |
| 6 | No Image Found | advanced | 300 | ECS, Fargate, task definitions, tasks | `level-6-ecr-image-missing` |
| 7 | Port Mismatch | advanced | 275 | ECS, Fargate, task definitions, tasks | `level-7-container-port-wrong` |
| 8 | Zero Tasks | advanced | 225 | ECS, Fargate, task definitions, tasks | `level-8-service-desired-zero` |
| 9 | App Crash at Startup | advanced | 250 | ECS, Fargate, task definitions, tasks | `level-9-env-var-missing` |
| 10 | Secret Not Found | advanced | 300 | ECS, Fargate, task definitions, secrets, tasks | `level-10-secrets-wrong-arn` |
| 11 | Permanently Unhealthy | advanced | 275 | ECS, Fargate, task definitions | `level-11-health-check-wrong` |
| 12 | No Logs | advanced | 275 | ECS, Fargate, task definitions, tasks | `level-12-log-driver-wrong` |
| 13 | No Internet in Private | advanced | 325 | ECS, Fargate, task definitions, subnets, routing | `level-13-subnet-no-nat` |
| 14 | Locked Container | advanced | 250 | ECS, Fargate, task definitions, tasks | `level-14-sg-no-outbound` |
| 15 | Can't Find Service | advanced | 375 | ECS, Fargate, task definitions | `level-15-service-discovery-missing` |

## Module 11: API Gateway (12 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | No API Exists | advanced | 250 | API Gateway, Lambda integration, stages, REST APIs | `level-1-api-missing` |
| 2 | No Path Configured | advanced | 250 | API Gateway, Lambda integration, stages, REST APIs | `level-2-resource-missing` |
| 3 | Wrong HTTP Method | advanced | 275 | API Gateway, Lambda integration, stages | `level-3-method-wrong` |
| 4 | No Backend | advanced | 300 | API Gateway, Lambda integration, stages, lambda functions, REST APIs | `level-4-integration-missing` |
| 5 | Wrong Lambda | advanced | 275 | API Gateway, Lambda integration, stages, lambda functions | `level-5-integration-wrong-arn` |
| 6 | API Can't Invoke Lambda | advanced | 300 | API Gateway, Lambda integration, stages, policy debugging, lambda functions | `level-6-lambda-permission-missing` |
| 7 | API Not Live | advanced | 250 | API Gateway, Lambda integration, stages, REST APIs | `level-7-not-deployed` |
| 8 | CORS Error | advanced | 325 | API Gateway, Lambda integration, stages, REST APIs | `level-8-cors-missing` |
| 9 | All Requests Throttled | advanced | 275 | API Gateway, Lambda integration, stages | `level-9-throttle-zero` |
| 10 | Authorization Required | advanced | 325 | API Gateway, Lambda integration, stages, REST APIs | `level-10-auth-wrong` |
| 11 | Garbled Request | advanced | 375 | API Gateway, Lambda integration, stages, lambda functions, templates | `level-11-mapping-template-wrong` |
| 12 | API Key Rejected | advanced | 375 | API Gateway, Lambda integration, stages, REST APIs | `level-12-api-key-no-plan` |

## Module 12: Production War Games (18 levels)

| # | Mission | Difficulty | XP | Concepts | Directory |
|---|---------|------------|----|----------|-----------|
| 1 | The Blocked Pipeline | expert | 400 | incident response, multi-service debugging, production troubleshooting, policy debugging, roles | `level-1-lambda-cant-read-s3` |
| 2 | The Silent Chain | expert | 450 | incident response, multi-service debugging, production troubleshooting, policy debugging, lambda functions | `level-2-sns-sqs-lambda-broken` |
| 3 | The Blind System | expert | 450 | incident response, multi-service debugging, production troubleshooting, alarms | `level-3-alarm-never-fires` |
| 4 | Upload Goes Nowhere | expert | 450 | incident response, multi-service debugging, production troubleshooting, policy debugging, buckets | `level-4-s3-trigger-broken` |
| 5 | The Dead API | expert | 500 | incident response, multi-service debugging, production troubleshooting, lambda functions, REST APIs | `level-5-api-gateway-full-break` |
| 6 | Container Chaos | expert | 500 | incident response, multi-service debugging, production troubleshooting, roles, tasks | `level-6-ecs-wont-start` |
| 7 | Stream Silence | expert | 475 | incident response, multi-service debugging, production troubleshooting, roles, lambda functions | `level-7-dynamodb-lambda-stream` |
| 8 | Stack Refuses to Update | expert | 475 | incident response, multi-service debugging, production troubleshooting, policy debugging | `level-8-cfn-stack-broken` |
| 9 | The Credential Crisis | expert | 500 | incident response, multi-service debugging, production troubleshooting, policy debugging, lambda functions | `level-9-secrets-rotation-cascade` |
| 10 | The Missing Bridge | expert | 500 | incident response, multi-service debugging, production troubleshooting, policy debugging, roles | `level-10-cross-account-role` |
| 11 | Security Audit | expert | 550 | incident response, multi-service debugging, production troubleshooting, policy debugging, roles | `level-11-iam-privilege-escalation` |
| 12 | Data Exposure Incident | expert | 550 | incident response, multi-service debugging, production troubleshooting, policy debugging, buckets | `level-12-public-s3-exposure` |
| 13 | Queue Meltdown | expert | 475 | incident response, multi-service debugging, production troubleshooting, policy debugging, alarms | `level-13-sqs-message-pileup` |
| 14 | Flying Blind | expert | 500 | incident response, multi-service debugging, production troubleshooting, lambda functions, alarms | `level-14-cloudwatch-observability-gap` |
| 15 | The Unreachable Service | expert | 550 | incident response, multi-service debugging, production troubleshooting, roles, subnets | `level-15-ecs-networking-labyrinth` |
| 16 | Encryption Lockout | expert | 550 | incident response, multi-service debugging, production troubleshooting, policy debugging, roles | `level-16-kms-breaks-everything` |
| 17 | The Auth Maze | expert | 575 | incident response, multi-service debugging, production troubleshooting, lambda functions, REST APIs | `level-17-api-auth-lockout` |
| 18 | The Production Incident | expert | 600 | incident response, multi-service debugging, production troubleshooting, policy debugging, buckets | `level-18-full-stack-incident` |
