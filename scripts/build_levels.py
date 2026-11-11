#!/usr/bin/env python3
"""Build levels.json and MODULES.md from each level's mission.yaml.

mission.yaml is the single source of truth. This script never creates or
scaffolds level content.
"""

from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
MODULES_DIR = ROOT / "modules"
LEVELS_PATH = ROOT / "levels.json"
MODULES_DOC = ROOT / "MODULES.md"

MODULE_TITLES = {
    "module-1-iam": "IAM Foundations",
    "module-2-s3": "S3 Mastery",
    "module-3-lambda": "Lambda Functions",
    "module-4-dynamodb": "DynamoDB",
    "module-5-sqs-sns": "SQS & SNS",
    "module-6-cloudwatch": "CloudWatch & Logging",
    "module-7-ec2-networking": "EC2 & Networking",
    "module-8-cloudformation": "CloudFormation",
    "module-9-secrets-config": "Secrets & Config",
    "module-10-ecs": "ECS & Containers",
    "module-11-api-gateway": "API Gateway",
    "module-12-step-functions": "Step Functions",
    "module-13-cognito": "Cognito",
    "module-14-load-balancing": "Load Balancing & Auto Scaling",
    "module-15-kinesis": "Kinesis & Firehose",
    "module-16-war-games": "Production War Games",
}
REQUIRED_KEYS = ("name", "description", "objective", "xp", "difficulty", "expected_time", "concepts")


def number_of(path: Path) -> int:
    match = re.match(r"(?:module|level)-(\d+)", path.name)
    return int(match.group(1)) if match else 10**6


def collect() -> tuple[list[dict], list[str]]:
    modules: list[dict] = []
    problems: list[str] = []
    for module_dir in sorted((p for p in MODULES_DIR.iterdir() if p.is_dir()), key=number_of):
        levels = []
        level_dirs = sorted((p for p in module_dir.iterdir() if p.is_dir() and p.name.startswith("level-")), key=number_of)
        seen_numbers: dict[int, str] = {}
        for level_dir in level_dirs:
            key = f"{module_dir.name}/{level_dir.name}"
            n = number_of(level_dir)
            if n in seen_numbers:
                problems.append(f"{key}: duplicate level number {n} (also {seen_numbers[n]})")
            seen_numbers[n] = level_dir.name
            mission_path = level_dir / "mission.yaml"
            if not mission_path.exists():
                problems.append(f"{key}: missing mission.yaml")
                continue
            mission = yaml.safe_load(mission_path.read_text(encoding="utf-8")) or {}
            missing = [k for k in REQUIRED_KEYS if k not in mission]
            if missing:
                problems.append(f"{key}: mission.yaml missing {', '.join(missing)}")
            levels.append(
                {
                    "key": key,
                    "number": n,
                    "path": str(level_dir.relative_to(ROOT)),
                    "mission": mission,
                }
            )
        modules.append({"name": module_dir.name, "title": MODULE_TITLES.get(module_dir.name, module_dir.name), "levels": levels})
    return modules, problems


def write_modules_doc(modules: list[dict]) -> None:
    total = sum(len(m["levels"]) for m in modules)
    lines = [
        "# AWSMissions Curriculum",
        "",
        "Generated from each level's `mission.yaml` by `scripts/build_levels.py`. Do not edit by hand.",
        "",
        f"**{total} missions across {len(modules)} modules.**",
        "",
    ]
    for index, module in enumerate(modules, start=1):
        lines += [f"## Module {index}: {module['title']} ({len(module['levels'])} levels)", ""]
        lines += ["| # | Mission | Difficulty | XP | Concepts | Directory |", "|---|---------|------------|----|----------|-----------|"]
        for level in module["levels"]:
            m = level["mission"]
            concepts = ", ".join(str(c) for c in m.get("concepts", []))
            lines.append(
                f"| {level['number']} | {m.get('name', '')} | {m.get('difficulty', '')} | {m.get('xp', '')} | {concepts} | `{level['key'].split('/')[1]}` |"
            )
        lines.append("")
    MODULES_DOC.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    modules, problems = collect()
    for problem in problems:
        print(f"warning: {problem}", file=sys.stderr)
    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "level_count": sum(len(m["levels"]) for m in modules),
        "modules": modules,
    }
    LEVELS_PATH.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    write_modules_doc(modules)
    print(f"levels.json: {payload['level_count']} levels in {len(modules)} modules")
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
