# Writing an AWSMissions level

Every mission drops the player into a broken AWS environment running in
[Floci](https://github.com/floci-io/floci), a local AWS emulator. The player
investigates, fixes it with the real `aws` CLI, and types `check`.

Reference level: `modules/module-1-iam/level-2-deny-effect/`. It sets the
quality bar. It is **not** a template to copy.

## The one rule: no shared templates

Each level is written by hand for its own scenario:

- Its own story: company or team, service names, resource names and the symptom
  someone noticed.
- Its own `setup.sh` that builds *this* breakage, a `validate.sh` that checks
  *this* fix by observing behaviour, and a `solution.sh`.
- Hints, solution and debrief written for this exact problem.

Do not write generators or generic "JSON path equals X" validators, and do not
copy-paste between levels and swap names. `scripts/check_uniqueness.py` flags
files that look alike across levels.

## Directory layout

```
modules/module-N-topic/level-M-short-slug/
  mission.yaml      briefing + metadata
  setup.sh          builds the broken environment (runs after an emulator reset)
  validate.sh       exit 0 = fixed, non-zero = not fixed; always prints why
  solution.sh       automated reference fix, used by the test harness only
  solution.md       reference fix explained for the player
  debrief.md        the lesson: why it broke, how AWS evaluates it, real-world tips
  hint-1.txt        a nudge: where to look and which command shows the problem
  hint-2.txt        the concept: what is wrong and why
  hint-3.txt        nearly the answer: the exact command shape
  workspace/        optional: files the player edits (policy.json, template.yaml, app.py ...)
```

`workspace/` is copied fresh into the player's working directory on every
(re)start. The player runs `aws` commands from that directory, so they can
use `file://policy.json`. `edit` opens these files.

## mission.yaml

```yaml
name: "Wrong Side of the Law"          # unique, short and evocative
description: >-                         # the story: who is affected, what symptom, what is known
  ...
objective: >-                           # the testable goal, including constraints (least privilege etc.)
  ...
xp: 100                                 # beginner 75-125, intermediate 150-225, advanced 250-350, expert 400-600
difficulty: beginner                    # beginner | intermediate | advanced | expert
expected_time: 6m
concepts: [IAM policy evaluation, explicit Deny]
services: [iam, s3, sts]
```

Do not include `implementation_status`, `module` or `level`; the path defines
those. The objective says *what* must be true. It must not give away the
command.

## Script contract

All three scripts:

- start with `#!/usr/bin/env bash` and `set -euo pipefail`
- `source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"`
- **must run on bash 3.2** (macOS `/bin/bash`), so none of these: `mapfile`,
  `declare -A`, `${x,,}`, `&>>`, GNU-only `sed -i ''`, `grep -P` or `date -d`. Use
  `python3` (stdlib only) or `jq` for anything non-trivial.
- talk to the emulator only through the `aws_local` / `aws_as_user` /
  `aws_as_role` / `aws_with_creds` helpers (they add `--endpoint-url`), and
  never hard-code `localhost:4566`.

| Script | cwd | Notes |
|---|---|---|
| `setup.sh` | level dir | Starts from an **empty** emulator (state was reset). Builds everything the story needs plus the breakage. It must be idempotent after a reset and must exit 0. Workspace files are at `$MISSION_DIR/workspace/...` (pristine) and `$WORKDIR/...` (the player's copy). |
| `validate.sh` | level dir | Checks **real emulator state and behaviour**. Never read files from `workspace/`, because the player edits a copy. On failure it prints a specific, helpful reason; it must not print the answer. |
| `solution.sh` | `$WORKDIR` | Performs the reference fix the way a player would: edits workspace files (with python3 or jq) and runs `aws_local ...`. |

Environment available to scripts: `AWSMISSIONS_ROOT`, `MISSION_DIR`,
`WORKDIR`, `AWS_ENDPOINT_URL`, `ACCOUNT_ID` (`000000000000`, after sourcing
the helpers), region `us-east-1`.

## Validators check behaviour, not configuration

Prefer actually *doing the thing*:

- IAM: call the API **as the principal** with `aws_as_user` / `aws_as_role`
  and expect success or `AccessDenied`.
- Lambda: invoke it and inspect the payload or `FunctionError`.
- SQS/SNS/EventBridge: publish and receive the message at the far end.
- API Gateway: `curl "$AWS_ENDPOINT_URL/restapis/$API_ID/$STAGE/_user_request_/path"`.
- CloudFormation: stack status, outputs, the resources it created.

Only fall back to reading configuration when there is no behaviour to observe.
Also guard against **lazy over-fixes** where it matters: `Action: "*"`,
`Resource: "*"`, `0.0.0.0/0`, or deleting the thing instead of fixing it. The
validator should reject these with a message explaining why.

## How Floci behaves (verified with 2.4.0)

- Mission env runs with `FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED=true`.
  - The default `test`/`test` credentials are the **account root** and bypass IAM.
  - Every other principal (IAM user keys, assumed-role sessions) is evaluated.
    Verified: identity policies, explicit Deny, groups, AWS managed policies,
    permission boundaries, trust policies, `sts:ExternalId`, condition keys,
    and S3 bucket policies.
  - Users are limited to 2 access keys, which is why `aws_as_user` deletes its throwaway key.
- State reset: `POST /_floci/state/reset` wipes everything, including
  containers spawned for Lambda and ECS. AWS managed policies stay seeded.
- Lambda runs real containers. The first invoke of a runtime takes about 10s.
  Bad handlers give `FunctionError: Unhandled`.
- ECS runs real containers (`nginx:alpine` works). The default VPC is
  `vpc-default-us-east-1`, subnets `subnet-default-us-east-1-[a-c]`.
- EC2: security groups, VPC resources, ~31 seeded AMIs.
- Spawned containers are named `floci-aws-<namespace>-<service>-...`, e.g.
  `floci-aws-${AWSMISSIONS_NAMESPACE}-ecs-<task id>-<container name>` or
  `floci-aws-${AWSMISSIONS_NAMESPACE}-ec2-<instance id>`. Never hard-code the
  namespace: it differs per emulator port. `AWSMISSIONS_NAMESPACE` is set by the
  engine, `aws_helpers.sh` and `./play.sh --env`.
- **Floci is lenient in places.** For example it accepted a CloudFormation
  template with resource type `AWS::S3::Buckett` and reported `CREATE_COMPLETE`.
  **Never assume a breakage reproduces.** The test harness proves it does. If
  Floci does not reproduce a failure, redesign the scenario around something
  it does enforce, keeping the same learning goal.

## Testing (mandatory)

```bash
AWSMISSIONS_PORT=46xx .venv/bin/python scripts/test_levels.py -v modules/module-N-topic/level-M-slug
.venv/bin/python scripts/check_uniqueness.py --focus modules/module-N-topic
.venv/bin/python scripts/build_levels.py
```

The harness resets the emulator and then:

1. runs static checks
2. `setup.sh` must succeed
3. `validate.sh` must **fail**, because the level must not be pre-solved
4. `solution.sh` must succeed
5. `validate.sh` must **pass**
6. `setup.sh` must work again after a reset
