# AWSMissions — Master Plan

> **Learn AWS by breaking it — then fixing it.**
>
> A fully local, game-based AWS training platform powered by LocalStack.
> No AWS account. No cloud costs. No fear of billing surprises.

---

## Concept

AWSMissions is a terminal-based, gamified AWS learning platform.
Each mission drops you into a deliberately broken AWS environment.
Your job: diagnose the problem and fix it using real `aws` CLI commands.

**196 progressive missions across 12 modules — from IAM basics to production war games.**
Fully local via LocalStack. Docker is the only prerequisite beyond the AWS CLI.

---

## How It Differs from Other Missions Games

| Aspect | k8smissions | terraformissions | awsmissions |
|---|---|---|---|
| Sandbox | `kind` Kubernetes cluster | Local filesystem `.tf` files | LocalStack (AWS emulator in Docker) |
| Broken state | YAML applied to cluster | Broken `.tf` files | Broken AWS resources seeded via `setup.sh` |
| Fix method | `kubectl` commands | Edit `.tf` files | `aws` CLI commands |
| Validator | Checks cluster state | Runs `terraform plan`/`apply` | Checks LocalStack state via AWS CLI |
| Reset | Delete namespace + re-apply | Restore `.tf` files + destroy | Re-run `setup.sh` (re-seeds broken state) |
| Prerequisites | Docker, kind, kubectl | Terraform CLI | Docker, AWS CLI, `awslocal` |

---

## Architecture

### File Structure

```
awsmissions/
├── play.sh                        ← Launch the game
├── install.sh                     ← One-time setup (venv + checks + LocalStack pull)
├── requirements.txt               ← Python dependencies (rich, boto3, pyyaml)
├── levels.json                    ← Pre-built level registry (auto-generated)
├── progress.json                  ← Player progress (auto-saved)
├── engine/
│   ├── engine.py                  ← Core game loop
│   ├── ui.py                      ← Rich terminal UI
│   ├── player.py                  ← Player profile + XP
│   ├── localstack.py              ← LocalStack lifecycle manager (start/stop/health)
│   ├── reset.py                   ← Level reset (re-runs setup.sh)
│   └── certificate.py            ← Module completion certificates
├── scripts/
│   ├── build_levels.py            ← Auto-generate levels.json from modules/
│   └── aws_helpers.sh             ← Shared bash helpers (awslocal alias, wait functions)
├── completion/
│   ├── _awsmissions               ← zsh completion
│   └── awsmissions.bash           ← bash completion
└── modules/
    ├── module-1-iam/
    │   └── level-1-name/
    │       ├── mission.yaml       ← Level metadata (name, description, XP, hints)
    │       ├── setup.sh           ← Seeds broken AWS state into LocalStack
    │       ├── validate.sh        ← Checks LocalStack state, exits 0 on pass
    │       ├── solution.md        ← Reference solution (AWS CLI commands to fix it)
    │       ├── hint-1.txt
    │       ├── hint-2.txt
    │       ├── hint-3.txt
    │       └── debrief.md         ← Post-mission lesson (why this matters in real AWS)
    └── ...
```

---

### LocalStack Setup (localstack.py)

LocalStack runs as a Docker container. The engine manages it automatically.

```python
LOCALSTACK_IMAGE = "localstack/localstack:latest"
LOCALSTACK_CONTAINER = "awsmissions-localstack"
LOCALSTACK_PORT = 4566
HEALTH_URL = "http://localhost:4566/_localstack/health"
```

**Lifecycle:**
1. `localstack.start()` — run `docker run -d --name awsmissions-localstack -p 4566:4566 localstack/localstack`
2. `localstack.wait_ready()` — poll `/_localstack/health` until `{"status":"running"}`
3. `localstack.stop()` — `docker stop awsmissions-localstack && docker rm awsmissions-localstack`
4. `localstack.reset()` — stop + start (full environment wipe between levels)
5. `localstack.is_running()` — check container state before any operation

**Between levels:** engine calls `localstack.reset()` to give each level a clean AWS environment. This prevents pollution from previous level's resources.

---

### AWS CLI Configuration for LocalStack

All `aws` CLI commands target LocalStack by setting the endpoint URL.

**Recommended approach — `awslocal` CLI wrapper (pip install awscli-local):**
```bash
awslocal s3 ls
awslocal iam list-roles
```

**Alternative — environment variables (set in engine before running setup.sh / validate.sh):**
```bash
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_ENDPOINT_URL=http://localhost:4566
```

The engine sets these env vars before calling any `setup.sh` or `validate.sh`.
Players run `aws` commands with the same env vars exported in their shell session.

**On level load, the engine prints:**
```
AWS environment ready. Use these commands in your terminal:
  export AWS_DEFAULT_REGION=us-east-1
  export AWS_ACCESS_KEY_ID=test
  export AWS_SECRET_ACCESS_KEY=test
  export AWS_ENDPOINT_URL=http://localhost:4566
  (or use: awslocal <command>)
```

---

### Level Lifecycle (reset.py)

On every level load or reset:
1. Call `localstack.reset()` — wipe LocalStack environment (stop + start container)
2. Wait for LocalStack to be healthy
3. Run `modules/module-X/level-Y/setup.sh` with LocalStack env vars set
4. Display mission briefing from `mission.yaml`

On validator run:
- `validate.sh` runs with LocalStack env vars set
- Script uses `aws` (or `awslocal`) commands to check state
- Exits `0` on pass, exits `1` on fail (with descriptive error message to stdout)
- Engine awards XP on exit code 0

---

### mission.yaml Structure

```yaml
name: "The Silent Policy"
description: "Your Lambda function returns AccessDenied when trying to read from S3. The function exists, the bucket exists, but every request is rejected."
objective: "Fix the IAM execution role so the Lambda function can call s3:GetObject on the target bucket."
xp: 200
difficulty: "beginner"
expected_time: "8m"
concepts:
  - IAM execution role
  - Lambda permissions
  - s3:GetObject
  - Resource-based vs identity-based policies
module: "module-1-iam"
level: "level-5-lambda-s3-access"
```

---

### setup.sh Pattern

Each `setup.sh` creates the broken AWS state. It runs in a clean LocalStack environment.

```bash
#!/usr/bin/env bash
# Level: Lambda can't read S3 — missing IAM permission
set -e

ENDPOINT="http://localhost:4566"
REGION="us-east-1"
ACCOUNT="000000000000"

# Create S3 bucket with a file
aws --endpoint-url=$ENDPOINT s3 mb s3://mission-bucket
echo "secret data" | aws --endpoint-url=$ENDPOINT s3 cp - s3://mission-bucket/data.txt

# Create IAM role with WRONG policy (missing s3:GetObject)
aws --endpoint-url=$ENDPOINT iam create-role \
  --role-name lambda-execution-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

aws --endpoint-url=$ENDPOINT iam put-role-policy \
  --role-name lambda-execution-role \
  --policy-name broken-policy \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:ListBucket"],"Resource":"*"}]}'
  # ^^^ Missing s3:GetObject — this is the bug

# Create Lambda function
aws --endpoint-url=$ENDPOINT lambda create-function \
  --function-name mission-function \
  --runtime python3.11 \
  --role arn:aws:iam::$ACCOUNT:role/lambda-execution-role \
  --handler index.handler \
  --zip-file fileb://$(dirname $0)/function.zip

echo "Setup complete. Lambda 'mission-function' cannot read from S3 bucket 'mission-bucket'."
```

---

### validate.sh Pattern

```bash
#!/usr/bin/env bash
# Validates: Lambda execution role has s3:GetObject permission
set -e

ENDPOINT="http://localhost:4566"

# Check the role policy includes s3:GetObject
POLICY=$(aws --endpoint-url=$ENDPOINT iam get-role-policy \
  --role-name lambda-execution-role \
  --policy-name broken-policy \
  --query 'PolicyDocument' --output json 2>/dev/null || echo "{}")

if echo "$POLICY" | grep -q '"s3:GetObject"' || echo "$POLICY" | grep -q '"s3:\*"'; then
  echo "PASS: Execution role now grants s3:GetObject."
  exit 0
else
  echo "FAIL: The role policy still does not grant s3:GetObject on the bucket."
  echo "Hint: Run: aws iam get-role-policy --role-name lambda-execution-role --policy-name broken-policy"
  exit 1
fi
```

---

### Game Commands (engine.py)

| Key | Command | Action |
|---|---|---|
| `1` | `check` | Run validate.sh, award XP if pass |
| `d` | `check-dry` | Dry-run — show if fix passes, no XP |
| `w` | `watch` | Auto-validate every 5s until pass |
| `2` | `hint` | Reveal next progressive hint |
| `3` | `solution` | Show solution.md (AWS CLI commands) |
| `4` | `debrief` | Show post-mission lesson |
| `5` | `describe` | Print current AWS resource state (helpful diagnostic) |
| `6` | `reset` | Re-run setup.sh (restore broken state) |
| `7` | `status` | Show progress across all modules |
| `8` | `skip` | Skip level (no XP) |
| `9` | `quit` | Save and exit |
| `0` | `reset-progress` | Wipe all progress |

---

### Prerequisites

| Tool | Required | Install |
|---|---|---|
| Docker | ✅ Yes | `https://docs.docker.com/get-docker/` |
| Python 3.9+ | ✅ Yes | `sudo apt install python3` |
| AWS CLI v2 | ✅ Yes | `sudo apt install awscli` |
| `awscli-local` | ✅ Yes | `pip install awscli-local` |
| `jq` | ✅ Yes | `sudo apt install jq` |
| `zip` | ✅ Yes | `sudo apt install zip` |

**No AWS account required. No cloud costs.**

---

### Python Dependencies (requirements.txt)

```
rich>=13.0
boto3>=1.28
pyyaml>=6.0
requests>=2.31
```

- `rich` — terminal UI (colors, panels, progress bars, tables)
- `boto3` — optional Python-based validators (complex assertions)
- `pyyaml` — parse mission.yaml
- `requests` — poll LocalStack health endpoint

---

### LocalStack Services Used

| AWS Service | LocalStack Support | Modules |
|---|---|---|
| IAM | ✅ Good | 1, 3, 8, 12 |
| S3 | ✅ Excellent | 2, 12 |
| Lambda | ✅ Good | 3, 12 |
| DynamoDB | ✅ Excellent | 4 |
| SQS | ✅ Excellent | 5 |
| SNS | ✅ Good | 5 |
| CloudWatch Logs | ✅ Good | 6 |
| CloudWatch Metrics/Alarms | ✅ Partial | 6 |
| EventBridge | ✅ Good | 6 |
| EC2 (basic) | ⚠️ Limited | 7 |
| VPC/Security Groups | ✅ Good | 7 |
| CloudFormation | ✅ Partial | 8 |
| KMS | ✅ Good | 9 |
| Secrets Manager | ✅ Good | 9 |
| SSM Parameter Store | ✅ Good | 9 |
| ECS | ✅ Partial | 10 |
| API Gateway | ✅ Partial | 11 |
| STS / AssumeRole | ✅ Good | 1, 12 |

---

## Learning Path — 12 Modules · 196 Levels

| # | Module | Levels | Est. XP | Difficulty | Key Services |
|---|--------|--------|---------|------------|--------------|
| 1 | 🟢 IAM Foundations | 20 | 3,000 | Beginner | IAM policies, roles, users, trust |
| 2 | 🟢 S3 Mastery | 20 | 3,200 | Beginner | Buckets, policies, ACLs, features |
| 3 | 🟢 Lambda Functions | 18 | 3,150 | Beginner | Functions, roles, triggers, config |
| 4 | 🟡 DynamoDB | 15 | 3,375 | Intermediate | Tables, indexes, streams, capacity |
| 5 | 🟡 SQS & SNS | 15 | 3,375 | Intermediate | Queues, topics, DLQs, subscriptions |
| 6 | 🟡 CloudWatch & Logging | 15 | 3,375 | Intermediate | Logs, alarms, metrics, EventBridge |
| 7 | 🟡 EC2 & Networking | 15 | 3,750 | Intermediate | SGs, VPC, subnets, routing |
| 8 | 🟡 CloudFormation | 18 | 4,950 | Intermediate | Stacks, templates, drift, exports |
| 9 | 🔴 Secrets & Config | 15 | 4,500 | Advanced | KMS, Secrets Manager, SSM |
| 10 | 🔴 ECS & Containers | 15 | 4,500 | Advanced | Tasks, services, roles, networking |
| 11 | 🔴 API Gateway | 12 | 3,900 | Advanced | REST APIs, integrations, auth |
| 12 | ⚫ Production War Games | 18 | 7,200 | Expert | Multi-service broken scenarios |
| **TOTAL** | | **196** | **~48,275** | | |

---

## install.sh Behavior

```bash
#!/usr/bin/env bash
# 1. Check Docker is installed and running
# 2. Check AWS CLI v2 is installed
# 3. Check awscli-local is installed (pip install awscli-local)
# 4. Check jq is installed
# 5. Pull LocalStack Docker image (docker pull localstack/localstack)
# 6. Create Python venv at ./venv
# 7. pip install -r requirements.txt
# 8. Run scripts/build_levels.py to generate levels.json
# 9. Print success + how to start
```

---

## play.sh Behavior

```bash
#!/usr/bin/env bash
# 1. Activate venv
# 2. Start LocalStack container if not running (via localstack.py)
# 3. Wait for LocalStack health check
# 4. Launch engine.py
```

---

## XP Progression

| Difficulty | XP Range | Time |
|---|---|---|
| Beginner | 100–175 | 5–10m |
| Intermediate | 175–300 | 10–20m |
| Advanced | 300–450 | 20–35m |
| Expert | 400–600 | 30–60m |

Module completion bonus: 500 XP
Full game completion: 2,000 XP bonus + certificate

---

## Certificate System (certificate.py)

On completing each module, a terminal ASCII certificate is displayed and saved to `~/.awsmissions/certificates/module-X.txt`.
On completing all 12 modules, a final "AWS Mission Commander" certificate is generated.
