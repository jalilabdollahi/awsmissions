# AWSMissions88

![platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-blue)
![shell](https://img.shields.io/badge/shell-bash-brightgreen)
![aws](https://img.shields.io/badge/aws-learning-orange)

> **Learn AWS by fixing it locally.**

AWSMissions is a fully local, terminal-based AWS training game powered by LocalStack. Each mission drops you into a deliberately broken cloud environment. Your job is to investigate what is wrong, repair it with real `aws` CLI commands, and validate the fix.

**196 progressive missions across 12 modules.**  
No AWS account. No cloud bill. No waiting on real infrastructure.

Design and implementation by: Jalil Abdollahi  
Email: `jalil.abdollahi@gmail.com`

---

## Features

- **196 missions** across 12 AWS-focused modules
- **Fully local gameplay** using LocalStack and Docker
- **Real AWS CLI workflow** instead of fake game commands
- **Rich terminal interface** powered by Python and Rich
- **Progressive hints** when you get stuck
- **Reference solutions** for every level
- **Debriefs** to explain what broke and why the fix works
- **Editable helper artifacts** like `policy.json`, `config.json`, `template.yaml`, and `task-definition.json`
- **XP tracking and progression** across the full curriculum
- **Resettable levels** so you can replay and practice

---

## Quick Start

```bash
cd awsmissions
./install.sh
./play.sh
```

What `install.sh` does:

- checks Python, Docker, AWS CLI, `jq`, and `zip`
- creates the local virtual environment
- installs Python dependencies
- installs `awscli-local`
- pulls the LocalStack Docker image
- builds the level registry

---

## Prerequisites

| Tool | Notes |
|------|-------|
| Docker | Must be installed and running |
| AWS CLI v2 | Used for all mission fixes |
| Python 3.9+ | Required for the game engine |
| `jq` | Used by some validators and helper scripts |
| `zip` | Used by Lambda-related levels |

Optional but recommended:

- `awslocal` via `awscli-local`

---

## How To Play

1. Run `./play.sh`
2. Keep that terminal open for the game loop
3. Use the same terminal or a second terminal to run `aws` commands
4. Read the mission briefing and hints
5. Repair the broken AWS resource locally
6. Run `check` to validate your fix
7. Earn XP and move to the next level

The engine exports the LocalStack endpoint for the mission environment, so the player should not need to manually pass endpoint flags during normal play.

---

## Commands

| Command | Description |
|---------|-------------|
| `check` | Run the validator |
| `hint` | Show the next hint |
| `reset` | Rebuild the AWS environment for the current level |
| `edit` | Open the helper file for the level |
| `solution` | Show the reference solution |
| `debrief` | Show the lesson summary |
| `status` | Show mission progress |
| `next` | Skip to the next mission |
| `aws ...` | Run an AWS CLI command directly |
| `quit` | Exit the game |

Shortcuts inside the game:

| Key | Command |
|-----|---------|
| `1` | `check` |
| `2` | `hint` |
| `3` | `reset` |
| `4` | `edit` |
| `5` | `solution` |
| `6` | `debrief` |
| `7` | `status` |
| `8` | `next` |
| `9` | `help` |
| `0` | `quit` |

---

## Learning Path

| # | Module | Levels | Focus |
|---|--------|--------|-------|
| 1 | IAM Foundations | 20 | policies, roles, trust relationships, permission debugging |
| 2 | S3 Mastery | 20 | buckets, policies, versioning, notifications, encryption |
| 3 | Lambda Functions | 18 | runtimes, handlers, permissions, triggers, function config |
| 4 | DynamoDB | 15 | tables, keys, GSIs, LSIs, TTL, PITR, streams |
| 5 | SQS & SNS | 15 | queues, topics, subscriptions, DLQs, delivery patterns |
| 6 | CloudWatch & Logging | 15 | logs, metrics, alarms, EventBridge |
| 7 | EC2 & Networking | 15 | VPCs, subnets, route tables, security groups, NACLs |
| 8 | CloudFormation | 18 | templates, stack lifecycle, mappings, parameters, drift |
| 9 | Secrets & Config | 15 | KMS, Secrets Manager, SSM Parameter Store |
| 10 | ECS & Containers | 15 | clusters, task definitions, roles, networking, service discovery |
| 11 | API Gateway | 12 | APIs, resources, methods, integrations, deployment, CORS |
| 12 | War Games | 18 | multi-failure incident response across services |

For the full level-by-level breakdown, see [MODULES.md](MODULES.md).

---

## How Missions Are Structured

Each level lives in its own directory under `modules/` and typically includes:

- `mission.yaml` for briefing and metadata
- `setup.sh` to create the broken state
- `validate.sh` to verify the repair
- `hint-1.txt`, `hint-2.txt`, `hint-3.txt`
- `solution.md`
- `debrief.md`

Some levels also include editable helper files such as:

- `policy.json`
- `trust-policy.json`
- `config.json`
- `bucket-policy.json`
- `task-definition.json`
- `template.yaml`
- `notification.json`

These editable files are intentional. They make it easier to teach the shape of AWS configurations without forcing the player to write long JSON or YAML blobs from scratch every time.

---

## Progression

XP is global across the full game, not tied to a single module.

- each completed level awards the XP listed in its `mission.yaml`
- rank progress is based on total XP
- a module can span multiple ranks
- the header progress bar shows progress toward the next rank threshold

Current rank thresholds:

- `0-199`: Cloud Recruit
- `200-499`: Cloud Operator
- `500-999`: Cloud Engineer
- `1000-1999`: Cloud Architect
- `2000-3999`: Cloud Commander
- `4000+`: Cloud Legend

---

## Project Structure

```text
awsmissions/
├── play.sh
├── install.sh
├── requirements.txt
├── README.md
├── MODULES.md
├── PLAN.md
├── progress.json
├── engine/
│   ├── engine.py
│   ├── ui.py
│   ├── player.py
│   ├── reset.py
│   ├── localstack.py
│   └── certificate.py
├── scripts/
│   ├── aws_helpers.sh
│   ├── build_levels.py
│   └── mission_runtime.py
└── modules/
    ├── module-1-iam/
    ├── module-2-s3/
    ├── module-3-lambda/
    ├── module-4-dynamodb/
    ├── module-5-sqs-sns/
    ├── module-6-cloudwatch/
    ├── module-7-ec2-networking/
    ├── module-8-cloudformation/
    ├── module-9-secrets-config/
    ├── module-10-ecs/
    ├── module-11-api-gateway/
    └── module-12-war-games/
```

---

## Resetting Progress

To reset only player progress:

```bash
./play.sh --reset-progress
```

To replay a level, use `reset` inside the game.

---

## Philosophy

AWSMissions is built around a simple idea:

- reading cloud docs is useful
- watching tutorials is useful
- but troubleshooting broken infrastructure yourself is where the lessons stick

The project is designed to help learners build practical AWS debugging instincts:

- what resource is actually broken
- where permissions really fail
- what exact AWS CLI command fixes the issue
- how to read policies, configs, and service metadata under pressure

---

## Notes

- Everything runs locally through LocalStack.
- You do not need an AWS account to play.
- Some advanced services are represented with helper artifacts to keep the missions local, fast, and teachable.
- Solutions and hints now explicitly tell the player which named resource a file applies to whenever possible.

---

## License

MIT License. See [LICENSE](LICENSE).
