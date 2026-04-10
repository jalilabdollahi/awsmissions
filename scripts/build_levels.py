#!/usr/bin/env python3
"""Generate the AWSMissions curriculum from MODULES.md."""

from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
MODULES_DOC = ROOT / "MODULES.md"
MODULES_DIR = ROOT / "modules"
LEVELS_PATH = ROOT / "levels.json"

MODULE_DIR_MAP = {
    1: "module-1-iam",
    2: "module-2-s3",
    3: "module-3-lambda",
    4: "module-4-dynamodb",
    5: "module-5-sqs-sns",
    6: "module-6-cloudwatch",
    7: "module-7-ec2-networking",
    8: "module-8-cloudformation",
    9: "module-9-secrets-config",
    10: "module-10-ecs",
    11: "module-11-api-gateway",
    12: "module-12-war-games",
}

MODULE_CONCEPTS = {
    1: ["IAM", "roles", "policies"],
    2: ["S3", "bucket configuration", "object access"],
    3: ["Lambda", "execution roles", "function configuration"],
    4: ["DynamoDB", "tables", "indexes"],
    5: ["SQS", "SNS", "event delivery"],
    6: ["CloudWatch", "logs", "alarms"],
    7: ["EC2", "VPC", "networking"],
    8: ["CloudFormation", "stacks", "templates"],
    9: ["Secrets Manager", "SSM", "KMS"],
    10: ["ECS", "Fargate", "task definitions"],
    11: ["API Gateway", "Lambda integration", "stages"],
    12: ["incident response", "multi-service debugging", "production troubleshooting"],
}


def natural_sort_key(path_or_name: Path | str) -> tuple[int, str]:
    name = path_or_name.name if isinstance(path_or_name, Path) else path_or_name
    match = re.search(r"(\d+)", name)
    return (int(match.group(1)), name) if match else (9999, name)


def parse_modules_doc() -> list[dict]:
    lines = MODULES_DOC.read_text(encoding="utf-8").splitlines()
    modules: list[dict] = []
    index = 0
    while index < len(lines):
        header_match = re.match(r"## Module (\d+): (.+?) \((.+)\)", lines[index])
        if not header_match:
            index += 1
            continue

        module_number = int(header_match.group(1))
        module_title = header_match.group(2).strip()
        module_dir = MODULE_DIR_MAP[module_number]
        module_data = {
            "number": module_number,
            "title": module_title,
            "dir": module_dir,
            "difficulty": "beginner",
            "levels": [],
        }

        index += 1
        while index < len(lines) and not lines[index].startswith("| # |"):
            difficulty_match = re.search(r"\*\*Learning goal:\*\*.*", lines[index])
            if difficulty_match:
                pass
            index += 1

        if index >= len(lines):
            break

        headers = [part.strip() for part in lines[index].strip().strip("|").split("|")]
        index += 2
        while index < len(lines) and lines[index].startswith("|"):
            raw_cells = [part.strip() for part in lines[index].strip().strip("|").split("|")]
            if module_number == 12 and len(headers) == 6 and len(raw_cells) == 7:
                raw_cells = [
                    raw_cells[0],
                    raw_cells[1],
                    raw_cells[2],
                    raw_cells[3],
                    raw_cells[5],
                    raw_cells[6],
                ]
            if len(raw_cells) != len(headers):
                index += 1
                continue
            row = dict(zip(headers, raw_cells))
            if not row.get("#", "").isdigit():
                index += 1
                continue
            module_data["levels"].append(normalize_row(module_data, row))
            index += 1

        modules.append(module_data)
    return modules


def normalize_row(module: dict, row: dict) -> dict:
    folder = row["Folder"].strip("`")
    name = row["Name"].strip()
    broken_key = next((key for key in row if key.startswith("Broken State")), "Broken State")
    broken_state = row.get(broken_key, "").strip()
    fix = row.get("Fix", "").strip()
    objective = fix or f"Diagnose and fix the misconfiguration(s) affecting {name.lower()}."
    difficulty = infer_difficulty(module["number"])
    xp = int(re.sub(r"[^0-9]", "", row["XP"]))
    expected_time = row["Time"].strip()
    concepts = infer_concepts(module["number"], name, broken_state, objective)
    return {
        "number": int(row["#"]),
        "folder": folder,
        "name": name,
        "broken_state": broken_state,
        "objective": objective,
        "xp": xp,
        "expected_time": expected_time,
        "difficulty": difficulty,
        "concepts": concepts,
        "module": module["dir"],
        "module_title": module["title"],
    }


def infer_difficulty(module_number: int) -> str:
    if module_number <= 3:
        return "beginner"
    if module_number <= 8:
        return "intermediate"
    if module_number <= 11:
        return "advanced"
    return "expert"


def infer_concepts(module_number: int, name: str, broken_state: str, objective: str) -> list[str]:
    concepts = list(MODULE_CONCEPTS[module_number])
    combined = f"{name} {broken_state} {objective}".lower()
    keyword_map = {
        "policy": "policy debugging",
        "role": "roles",
        "bucket": "buckets",
        "lambda": "lambda functions",
        "alarm": "alarms",
        "queue": "queues",
        "topic": "topics",
        "stream": "streams",
        "vpc": "VPCs",
        "subnet": "subnets",
        "route": "routing",
        "template": "templates",
        "secret": "secrets",
        "parameter": "parameter store",
        "task": "tasks",
        "api": "REST APIs",
    }
    for needle, label in keyword_map.items():
        if needle in combined and label not in concepts:
            concepts.append(label)
    return concepts[:5]


def mission_payload(level: dict) -> dict:
    return {
        "name": level["name"],
        "description": level["broken_state"],
        "objective": level["objective"],
        "xp": level["xp"],
        "difficulty": level["difficulty"],
        "expected_time": level["expected_time"],
        "concepts": level["concepts"],
        "module": level["module"],
        "module_title": level["module_title"],
        "level": level["folder"],
        "implementation_status": "playable",
    }


def hint_texts(level: dict) -> tuple[str, str, str]:
    return (
        f"Start by inspecting the resources involved in this mission: {level['broken_state']}",
        f"Focus on the specific mismatch described in the objective: {level['objective']}",
        "Use the AWS CLI command family for this service and compare the current state against the target configuration.",
    )


def solution_text(level: dict) -> str:
    command_family = level["module"].split("-")[-1]
    return "\n".join(
        [
            f"# Solution: {level['name']}",
            "",
            "## The Problem",
            level["broken_state"],
            "",
            "## Fix",
            "```bash",
            f"# Inspect the current state first",
            f"aws {command_family} help",
            "",
            f"# Then apply the fix described by the mission",
            f"# {level['objective']}",
            "```",
            "",
            "## Verify",
            "```bash",
            "# Re-run the relevant describe/get/list command and confirm the resource now matches the objective",
            "```",
        ]
    )


def debrief_text(level: dict) -> str:
    return "\n".join(
        [
            f"# {level['name']}",
            "",
            "## Why This Matters",
            f"This mission practices a real troubleshooting pattern in {level['module_title']}: {level['broken_state']}",
            "",
            "## Production Lesson",
            "In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.",
            "",
            "## Key Concepts",
            *[f"- {concept}" for concept in level["concepts"]],
        ]
    )


def scaffold_setup(level: dict) -> str:
    return "\n".join(
        [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            'python3 ../../../scripts/mission_runtime.py setup "$(cd "$(dirname "$0")" && pwd)"',
        ]
    )


def scaffold_validate(level: dict) -> str:
    return "\n".join(
        [
            "#!/usr/bin/env bash",
            'python3 ../../../scripts/mission_runtime.py validate "$(cd "$(dirname "$0")" && pwd)"',
        ]
    )


def write_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.rstrip() + "\n", encoding="utf-8")


def maybe_write(path: Path, content: str, executable: bool = False) -> None:
    if path.exists():
        return
    write_file(path, content)
    if executable:
        path.chmod(0o755)


def scaffold_levels(modules: list[dict]) -> None:
    for module in modules:
        module_dir = MODULES_DIR / module["dir"]
        module_dir.mkdir(parents=True, exist_ok=True)
        for level in module["levels"]:
            level_dir = module_dir / level["folder"]
            level_dir.mkdir(parents=True, exist_ok=True)
            mission_path = level_dir / "mission.yaml"

            if not mission_path.exists():
                mission = mission_payload(level)
                write_file(mission_path, yaml.safe_dump(mission, sort_keys=False, allow_unicode=False))

            hint_1, hint_2, hint_3 = hint_texts(level)
            maybe_write(level_dir / "hint-1.txt", hint_1)
            maybe_write(level_dir / "hint-2.txt", hint_2)
            maybe_write(level_dir / "hint-3.txt", hint_3)
            maybe_write(level_dir / "solution.md", solution_text(level))
            maybe_write(level_dir / "debrief.md", debrief_text(level))
            maybe_write(level_dir / "setup.sh", scaffold_setup(level), executable=True)
            maybe_write(level_dir / "validate.sh", scaffold_validate(level), executable=True)


def collect_levels() -> list[dict]:
    levels: list[dict] = []
    for module_dir in sorted((path for path in MODULES_DIR.iterdir() if path.is_dir()), key=natural_sort_key):
        for level_dir in sorted((path for path in module_dir.iterdir() if path.is_dir()), key=natural_sort_key):
            mission_path = level_dir / "mission.yaml"
            if not mission_path.exists():
                continue
            mission = yaml.safe_load(mission_path.read_text(encoding="utf-8"))
            levels.append(
                {
                    "id": f"{module_dir.name}/{level_dir.name}",
                    "name": level_dir.name,
                    "path": str(level_dir.relative_to(ROOT)),
                    "mission": mission,
                }
            )
    return levels


def build_registry(levels: list[dict]) -> dict:
    modules: dict[str, list[dict]] = {}
    for level in levels:
        module_name = level["mission"]["module"]
        modules.setdefault(module_name, []).append(level)
    ordered_modules = [
        {"name": module_name, "levels": sorted(module_levels, key=lambda item: natural_sort_key(item["name"]))}
        for module_name, module_levels in sorted(modules.items(), key=lambda item: natural_sort_key(item[0]))
    ]
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "level_count": len(levels),
        "modules": ordered_modules,
    }


def main() -> int:
    modules = parse_modules_doc()
    scaffold_levels(modules)
    levels = collect_levels()
    LEVELS_PATH.write_text(json.dumps(build_registry(levels), indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(levels)} levels to {LEVELS_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
