# AWSMissions

Learn AWS by fixing deliberately broken infrastructure locally with LocalStack.

This MVP includes:

- A terminal game loop powered by Python and Rich
- Automatic LocalStack lifecycle management through Docker
- Resettable AWS missions implemented with `setup.sh` and `validate.sh`
- Progress tracking and XP awards
- A starter curriculum with IAM and S3 missions
- A generated full curriculum covering all 196 planned missions with shared runtime-backed setup and validation

## Quick Start

```bash
./install.sh
./play.sh
```

## Prerequisites

- Docker
- AWS CLI v2
- Python 3.10+

Optional but recommended:

- `awslocal` from `awscli-local`

## How Missions Work

Each level contains:

- `mission.yaml` for metadata
- `setup.sh` to seed broken LocalStack resources
- `validate.sh` to confirm the fix
- `hint-*.txt`, `solution.md`, and `debrief.md` for learning support

The engine resets LocalStack before loading a level, runs the level setup, and then waits for the player to repair the environment with real `aws` CLI commands.

## Progression

- XP is global across the whole game, not per module.
- Each completed level awards the XP listed in its `mission.yaml`.
- Modules can contain many levels, so a single module may span multiple ranks.
- The header XP bar shows progress toward the next rank threshold, not completion of the current module.

Current rank thresholds:

- `0-199`: Cloud Recruit
- `200-499`: Cloud Operator
- `500-999`: Cloud Engineer
- `1000-1999`: Cloud Architect
- `2000-3999`: Cloud Commander
- `4000+`: Cloud Legend

## Current Coverage

- The repository now contains the full 12-module, 196-level curriculum structure from `MODULES.md`.
- All levels now ship with runnable `setup.sh` and `validate.sh` entrypoints.
- Earlier handcrafted missions still provide the richest service-specific behavior, while the shared runtime keeps the rest of the curriculum playable and centrally maintainable.
