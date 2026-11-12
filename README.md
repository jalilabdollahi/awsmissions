# AWSMissions

![platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-blue)
![shell](https://img.shields.io/badge/shell-bash-brightgreen)
![aws](https://img.shields.io/badge/aws-learning-orange)
![emulator](https://img.shields.io/badge/emulator-Floci-9cf)

> **Learn AWS by fixing it locally.**

AWSMissions is a terminal game that teaches AWS through troubleshooting. Each
mission drops you into a deliberately broken AWS environment running on your
own machine. You investigate what is wrong, repair it with real `aws` CLI
commands, and type `check`. The validator then tests the result the way
production would: it uploads as the role, invokes the function, sends the
message or calls the API.

**268 missions across 16 modules.**
You don't need an AWS account, there is no cloud bill, and no real
infrastructure to wait on.

The emulator is [Floci](https://github.com/floci-io/floci), a free, open-source,
LocalStack-compatible AWS emulator with real IAM policy evaluation. Lambda
functions, ECS tasks and EC2 instances run as real containers.

Design and implementation by: Jalil Abdollahi

---

## Features

- **268 hand-written missions.** Each one has its own story, broken environment, validator, hints and debrief. None are generated from templates.
- **Behaviour checks.** IAM is enforced, so a fix is proven by acting as the affected principal, not by reading a JSON field. Over-broad fixes such as `"Action": "*"` or `0.0.0.0/0` are rejected with an explanation.
- **Real AWS CLI workflow.** You type the same commands you would use against AWS.
- **Safe by design.** In-game commands use isolated credentials and an explicit local endpoint, so they can never reach your real AWS account.
- **Progressive hints:** where to look, then the concept, then the command shape.
- **Debriefs** explain how AWS evaluates what you just fixed, plus real-world tips.
- **XP, ranks and module certificates.**
- **Fast resets.** The emulator state is wiped in about a second between missions.

---

## Quick Start

```bash
cd awsmissions
./install.sh
./play.sh
```

What `install.sh` does:

- checks Python 3.9+, Docker, AWS CLI v2, `jq` and `zip` (and installs what it can)
- creates or repairs the local virtual environment and installs Python dependencies
- pulls the pinned Floci image (`floci/floci:2.4.0`)
- builds the level registry (`levels.json`, `MODULES.md`)

`./play.sh` starts the emulator container (`awsmissions-floci`, port 4566) on
first use and keeps it running between sessions. `./play.sh --stop` stops it and
removes the EC2, Lambda and ECS containers the emulator started.

---

## Prerequisites

| Tool | Notes |
|------|-------|
| Docker | Must be installed and running |
| AWS CLI v2 | Used for all mission fixes (2.13+ recommended) |
| Python 3.9+ | Runs the game engine |
| `jq`, `zip` | Used by some missions (Lambda packaging, JSON edits) |

---

## How To Play

1. Run `./play.sh` and read the mission briefing.
2. Investigate with `aws ...` commands typed straight at the game prompt.
3. Edit helper files with `edit` if the mission provides them, then apply them with `file://name`.
4. Type `check`. If the fix is right you earn XP and move on; if not, the validator tells you what is still wrong.

### Commands

| Command | Key | Description |
|---------|-----|-------------|
| `check` | `1` | Run the validator |
| `hint` | `2` | Show the next hint |
| `reset` | `3` | Rebuild the broken environment and restore the workspace files |
| `edit [file]` | `4` | Open a workspace file in `$EDITOR` |
| `solution` | `5` | Show the reference solution |
| `debrief` | `6` | Show the lesson summary |
| `status` | `7` | Show progress across all missions |
| `next` | `8` | Skip to the next mission |
| `help` | `9` | Show the command list |
| `quit` | `0` | Exit the game |
| `aws ...` | | Run an AWS CLI command against the emulator |
| `files` | | List the mission's workspace files |
| `shell` | | Open a mission shell (the AWS CLI is pre-wired to the emulator); `exit` returns to the game |
| `!cmd` | | Run one shell command in the workspace, e.g. `!zip function.zip app.py` |

### Using a second terminal

A plain terminal uses **your real AWS credentials**. Point it at the emulator first:

```bash
eval "$(./play.sh --env)"
```

This hides `~/.aws` profiles, sets the local endpoint and test credentials
(plus `AWSMISSIONS_PORT` and `AWSMISSIONS_NAMESPACE`), and prefixes your prompt with `(awsmissions)`.

---

## Learning Path

| # | Module | Levels | Focus |
|---|--------|--------|-------|
| 1 | IAM Foundations | 21 | policies, roles, trust, boundaries, conditions, resource policies |
| 2 | S3 Mastery | 20 | bucket and object access, versioning, CORS, lifecycle, events, encryption |
| 3 | Lambda Functions | 20 | runtimes, handlers, roles, limits, destinations, layers, triggers, URLs |
| 4 | DynamoDB | 16 | keys, indexes, TTL, streams, capacity, conditional writes, tenant isolation |
| 5 | SQS & SNS | 17 | queues, DLQs and redrive, FIFO, fan-out, filter policies, message size |
| 6 | CloudWatch & Logging | 17 | metrics, alarms, logs, metric filters, dashboards, EventBridge |
| 7 | EC2 & Networking | 17 | VPCs, subnets, routes, gateways, security groups, NACLs, peering, endpoints |
| 8 | CloudFormation | 18 | templates, parameters, intrinsics, exports, policies, nested stacks, drift |
| 9 | Secrets & Config | 15 | KMS, Secrets Manager, SSM Parameter Store, rotation, leaked credentials |
| 10 | ECS & Containers | 16 | clusters, task definitions, roles, logging, networking, services, deployments |
| 11 | API Gateway | 15 | REST and HTTP APIs, integrations, stages, authorizers, CORS, usage plans |
| 12 | Step Functions | 14 | execution roles, Choice, paths, Retry/Catch, Map/Parallel, callbacks |
| 13 | Cognito | 14 | user pools, auth flows, tokens and claims, triggers, hosted UI, recovery |
| 14 | Load Balancing & Auto Scaling | 14 | ALB routing, target health, redirects, stickiness, Auto Scaling, blue/green |
| 15 | Kinesis & Firehose | 14 | shards, partition keys, iterators, consumers, Firehose delivery and transforms |
| 16 | Production War Games | 20 | multi-fault production incidents across services |

For the full level-by-level breakdown, see [MODULES.md](MODULES.md).

---

## How Missions Are Built

Each level lives in `modules/module-N-topic/level-M-slug/`:

| File | Purpose |
|------|---------|
| `mission.yaml` | Briefing, objective, XP, difficulty, concepts, services |
| `setup.sh` | Builds the broken environment in a freshly reset emulator |
| `validate.sh` | Checks real emulator behaviour and explains what is still wrong |
| `solution.sh` | Automated reference fix, used by the test harness |
| `hint-1..3.txt`, `solution.md`, `debrief.md` | Player-facing guidance |
| `workspace/` | Files the player edits; copied fresh on every (re)start |

The full contract for contributors is in [LEVEL_SPEC.md](LEVEL_SPEC.md).

### Testing missions

```bash
# setup → validate must FAIL → solution → validate must PASS → setup repeatable
.venv/bin/python scripts/test_levels.py modules/module-1-iam
.venv/bin/python scripts/test_levels.py modules/module-3-lambda/level-7-*
.venv/bin/python scripts/test_levels.py modules        # every level, in curriculum order

# run on a separate emulator so it doesn't disturb a game in progress
AWSMISSIONS_PORT=4601 .venv/bin/python scripts/test_levels.py modules/module-2-s3

# flag levels that look template-generated
.venv/bin/python scripts/check_uniqueness.py

# rebuild levels.json and MODULES.md after adding or renaming levels
.venv/bin/python scripts/build_levels.py
```

---

## Progression

XP is global across the whole game. Each completed level awards the XP in its
`mission.yaml`, and finishing every level of a module saves a certificate to
`certificates/`. Progress is keyed by level directory, so adding new levels
never disturbs saved progress.

| XP | Rank |
|----|------|
| 0–199 | Cloud Recruit |
| 200–499 | Cloud Operator |
| 500–999 | Cloud Engineer |
| 1000–1999 | Cloud Architect |
| 2000–3999 | Cloud Commander |
| 4000+ | Cloud Legend |

To reset progress: `./play.sh --reset-progress`. To replay a level, use `reset` inside the game.

---

## Project Structure

```text
awsmissions/
├── play.sh                 # start the game (--env, --stop, --reset-progress)
├── install.sh
├── LEVEL_SPEC.md           # how to write a mission
├── MODULES.md              # generated curriculum
├── levels.json             # generated registry
├── engine/
│   ├── engine.py           # game loop and commands
│   ├── floci.py            # emulator lifecycle and state reset
│   ├── reset.py            # isolated mission environment, setup/validate
│   ├── player.py           # progress
│   ├── ui.py
│   └── certificate.py
├── scripts/
│   ├── aws_helpers.sh      # aws_local, aws_as_user, aws_as_role, wait_for
│   ├── test_levels.py      # end-to-end mission tests
│   ├── check_uniqueness.py
│   └── build_levels.py
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
    ├── module-12-step-functions/
    ├── module-13-cognito/
    ├── module-14-load-balancing/
    ├── module-15-kinesis/
    └── module-16-war-games/
```

---

## Emulator notes

Floci is a very capable emulator, but it is not AWS. A few behaviours differ
(for example, some CloudFormation template errors are accepted, and some
service-to-service resource policies are not enforced). Every mission was
built and tested against the pinned Floci version, and debriefs say so where
the emulator differs from real AWS.

- Floci's state reset keeps CloudFormation stacks and some ECS task state, so
  the engine restarts the container after levels that use those services. This
  takes a few seconds.
- The first Lambda invoke of a runtime pulls and starts a container, which can
  take about 10 seconds.
- Containers Floci spawns (EC2 instances, Lambda functions, ECS tasks) are
  named `floci-aws-<namespace>-<service>-...`. The namespace is `awsmissions`
  on the default port 4566 and `awsm<port>` on any other port, so parallel
  emulators never collide. Spawned containers and networks are removed whenever
  the engine restarts or stops the emulator.

---

## License

MIT License.
