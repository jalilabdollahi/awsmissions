#!/usr/bin/env python3
"""AWSMissions main game loop."""

from __future__ import annotations

import json
import os
import readline  # noqa: F401
import shlex
import shutil
import subprocess
import sys
import time
from pathlib import Path

import yaml
from rich.prompt import Prompt

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from engine.certificate import render_certificate, save_certificate
from engine.localstack import aws_cli_available, docker_available
from engine.player import PlayerProgress
from engine.reset import mission_env, prepare_level, validate_level
from engine.ui import (
    console,
    show_deep_hint,
    show_environment,
    show_help,
    show_hint,
    show_menu,
    show_mission,
    show_module_complete,
    show_status,
    show_text_file,
    show_title,
    show_validation,
)

LEVELS_PATH = REPO_ROOT / "levels.json"
PROGRESS_PATH = REPO_ROOT / "progress.json"
SANDBOX_ROOT = REPO_ROOT / ".sandboxes"
COMMAND_ALIASES = {
    "1": "check",
    "2": "hint",
    "3": "reset",
    "4": "edit",
    "5": "solution",
    "6": "debrief",
    "7": "status",
    "8": "next",
    "9": "help",
    "0": "quit",
    "q": "quit",
    "e": "edit",
}
COMMAND_NAMES = [
    "check",
    "hint",
    "reset",
    "edit",
    "solution",
    "debrief",
    "status",
    "next",
    "help",
    "quit",
    "aws",
    "awslocal",
]


def prettify_module_title(module_name: str) -> str:
    known = {
        "module-1-iam": "IAM",
        "module-2-s3": "S3",
        "module-3-lambda": "Lambda",
        "module-4-dynamodb": "DynamoDB",
        "module-5-sqs-sns": "SQS & SNS",
        "module-6-cloudwatch": "CloudWatch",
        "module-7-ec2-networking": "EC2 & Networking",
        "module-8-cloudformation": "CloudFormation",
        "module-9-secrets-config": "Secrets & Config",
        "module-10-ecs": "ECS & Containers",
        "module-11-api-gateway": "API Gateway",
        "module-12-war-games": "Production War Games",
    }
    return known.get(module_name, module_name)


def load_levels() -> list[dict]:
    with LEVELS_PATH.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    if isinstance(payload, list):
        return payload
    if isinstance(payload, dict) and "modules" in payload:
        flattened: list[dict] = []
        next_id = 1
        for module in payload["modules"]:
            module_name = module["name"]
            for level in module["levels"]:
                mission = level.get("mission", {})
                module_level_number = len(flattened) + 1
                try:
                    module_level_number = int(level["name"].split("-")[1])
                except (IndexError, ValueError):
                    pass
                flattened.append(
                    {
                        "id": next_id,
                        "name": mission.get("name", level["name"]),
                        "description": mission.get("description", ""),
                        "objective": mission.get("objective", ""),
                        "xp": int(mission.get("xp", 0)),
                        "difficulty": mission.get("difficulty", "beginner"),
                        "module_name": mission.get("module", module_name),
                        "module_title": mission.get("module_title", prettify_module_title(module_name)),
                        "module_level_number": module_level_number,
                        "path": level["path"],
                        "implementation_status": mission.get("implementation_status", "playable"),
                    }
                )
                next_id += 1
        return flattened
    raise ValueError("Unsupported levels.json format")


def level_by_id(levels: list[dict], level_id: int) -> dict | None:
    for level in levels:
        if level["id"] == level_id:
            return level
    return None


def is_playable(level: dict) -> bool:
    return level.get("implementation_status", "playable") != "scaffolded"


def playable_levels(levels: list[dict]) -> list[dict]:
    return [level for level in levels if is_playable(level)]


def level_path(level: dict) -> Path:
    return REPO_ROOT / level["path"]


def editable_candidates(level: dict) -> list[str]:
    candidates = [
        "policy.json",
        "bucket-policy.json",
        "trust-policy.json",
        "task-definition.json",
        "template.yaml",
        "config.json",
    ]
    return [name for name in candidates if (level_path(level) / name).exists()]


def sandbox_path(level: dict) -> Path:
    return SANDBOX_ROOT / level["path"]


def ensure_level_sandbox(level: dict, reset: bool = False) -> Path:
    source_dir = level_path(level)
    target_dir = sandbox_path(level)
    target_dir.mkdir(parents=True, exist_ok=True)

    for name in editable_candidates(level):
        source = source_dir / name
        target = target_dir / name
        if reset or not target.exists():
            shutil.copy2(source, target)

    return target_dir


def editable_target(level: dict) -> Path | None:
    sandbox_dir = ensure_level_sandbox(level)
    for name in editable_candidates(level):
        path = sandbox_dir / name
        if path.exists():
            return path
    return None


def open_editor(path: Path) -> None:
    editor = os.environ.get("EDITOR") or os.environ.get("VISUAL") or "nano"
    subprocess.run([editor, str(path)], check=False)


def configure_readline(level: dict) -> None:
    level_dir = ensure_level_sandbox(level)

    def completer(text: str, state: int) -> str | None:
        buffer = readline.get_line_buffer()
        tokens = buffer.split()
        candidates: list[str] = []

        if not tokens:
            candidates.extend(COMMAND_NAMES)
        elif len(tokens) == 1 and not buffer.endswith(" "):
            candidates.extend(COMMAND_NAMES)
        else:
            file_candidates = [path.name for path in level_dir.iterdir()]
            file_candidates.extend([f"file://{path.name}" for path in level_dir.iterdir()])
            candidates.extend(file_candidates)

        matches = sorted(candidate for candidate in set(candidates) if candidate.startswith(text))
        if state < len(matches):
            return matches[state]
        return None

    readline.set_completer_delims(" \t\n")
    readline.parse_and_bind("tab: complete")
    readline.set_completer(completer)


def read_command(level: dict) -> str:
    configure_readline(level)
    try:
        command = Prompt.ask("awsmissions", default="check").strip()
    except KeyboardInterrupt:
        console.print("\n[yellow]Exiting AWSMissions.[/yellow]")
        raise SystemExit(0)

    while command.endswith("\\"):
        command = command[:-1].rstrip()
        try:
            continuation = Prompt.ask("...").strip()
        except KeyboardInterrupt:
            console.print("\n[yellow]Exiting AWSMissions.[/yellow]")
            raise SystemExit(0)
        command = f"{command} {continuation}".strip()

    return command.lower() if command in COMMAND_ALIASES or command in COMMAND_NAMES else command


def run_player_command(raw_command: str, level: dict) -> None:
    command = raw_command.strip()
    if not command:
        return
    if command.startswith("awslocal "):
        command = "aws " + command[len("awslocal "):]

    try:
        args = shlex.split(command)
    except ValueError as exc:
        os.system("clear")
        console.print(f"[red]Could not parse command:[/red] {exc}")
        return

    if not args or args[0] != "aws":
        os.system("clear")
        console.print("[yellow]Only AWS CLI commands are supported directly in-game right now. Use `aws ...`.[/yellow]")
        return

    os.system("clear")
    sandbox_dir = ensure_level_sandbox(level)
    console.print(f"[grey70]Running in {sandbox_dir}[/grey70]")
    subprocess.run(args, cwd=sandbox_dir, env=mission_env(), check=False)


def module_completed(levels: list[dict], progress: PlayerProgress, module_name: str) -> bool:
    completed = set(progress.data.get("completed_levels", []))
    module_levels = [level for level in levels if level["module_name"] == module_name]
    if any(not is_playable(level) for level in module_levels):
        return False
    module_level_ids = {level["id"] for level in module_levels}
    return bool(module_level_ids) and module_level_ids.issubset(completed)


def first_incomplete_level(levels: list[dict], progress: PlayerProgress) -> dict | None:
    completed = set(progress.data.get("completed_levels", []))
    for level in playable_levels(levels):
        if level["id"] not in completed:
            return level
    playable = playable_levels(levels)
    return playable[-1] if playable else None


def ensure_player_name(progress: PlayerProgress) -> None:
    if progress.data.get("player_name"):
        return
    name = Prompt.ask("Choose your agent name", default="Cloud Engineer").strip() or "Cloud Engineer"
    progress.set_player_name(name)


def ensure_prerequisites() -> bool:
    missing: list[str] = []
    if not docker_available():
        missing.append("Docker")
    if not aws_cli_available():
        missing.append("AWS CLI")
    if missing:
        console.print(f"[red]Missing prerequisites:[/red] {', '.join(missing)}")
        return False
    return True


def current_level(progress: PlayerProgress, levels: list[dict]) -> dict | None:
    configured = level_by_id(playable_levels(levels), int(progress.data.get("current_level_id", 1)))
    return configured or first_incomplete_level(levels, progress)


def load_mission(level: dict) -> dict:
    with (level_path(level) / "mission.yaml").open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def build_detailed_hint(level: dict, mission: dict) -> str:
    solution_path = level_path(level) / "solution.md"
    solution_excerpt = ""
    if solution_path.exists():
        lines = [line.rstrip() for line in solution_path.read_text(encoding="utf-8").splitlines() if line.strip()]
        excerpt_lines: list[str] = []
        capture = False
        for line in lines:
            if line.startswith("```"):
                if capture:
                    break
                capture = True
                continue
            if capture:
                excerpt_lines.append(line)
            if len(excerpt_lines) >= 8:
                break
        if excerpt_lines:
            solution_excerpt = "\n".join(excerpt_lines)

    parts = [
        "You have already used the standard hints. Here is a more direct nudge.",
        "",
        f"Target: {mission.get('objective', level.get('objective', ''))}",
        f"Focus resource: {level.get('name', 'this mission')}",
    ]
    if solution_excerpt:
        parts.extend(
            [
                "",
                "Suggested command shape:",
                solution_excerpt,
            ]
        )
    else:
        parts.extend(
            [
                "",
                "Next step:",
                "Compare the current AWS resource configuration with the objective, then re-run the matching update command.",
            ]
        )
    parts.extend(
        [
            "",
            "If you want the full reference answer, use command 4 (`solution`).",
        ]
    )
    return "\n".join(parts)


def maybe_award_module(levels: list[dict], progress: PlayerProgress, level: dict) -> None:
    if not module_completed(levels, progress, level["module_name"]):
        return
    if not progress.award_module_certificate(level["module_name"]):
        return
    cert = render_certificate(level["module_title"], progress.data.get("player_name") or "Cloud Engineer")
    save_certificate(REPO_ROOT, level["module_name"], cert)
    show_module_complete(cert)


def move_to_next_level(levels: list[dict], progress: PlayerProgress, current_id: int) -> dict | None:
    active_levels = playable_levels(levels)
    for index, level in enumerate(active_levels):
        if level["id"] != current_id:
            continue
        if index + 1 < len(active_levels):
            next_level = active_levels[index + 1]
            progress.set_current_level(next_level["id"])
            return next_level
        return None
    return None


def prepare_current_level(level: dict) -> None:
    console.print("[grey70]Resetting LocalStack and seeding the mission...[/grey70]")
    ensure_level_sandbox(level, reset=True)
    prepare_level(level_path(level))


def main() -> int:
    if not LEVELS_PATH.exists():
        console.print("[red]levels.json is missing. Run ./install.sh first.[/red]")
        return 1

    if not ensure_prerequisites():
        return 1

    levels = load_levels()
    if not playable_levels(levels):
        console.print("[red]No playable levels are currently implemented.[/red]")
        return 1
    progress = PlayerProgress(PROGRESS_PATH)
    ensure_player_name(progress)
    os.system("clear")
    show_title(progress.data.get("player_name") or "Cloud Engineer", progress.data.get("total_xp", 0))
    show_environment()

    level = current_level(progress, levels)
    if level is None:
        console.print("[red]No levels found.[/red]")
        return 1

    prepare_current_level(level)

    while True:
        levels = load_levels()
        level = current_level(progress, levels)
        if level is None:
            console.print("[green]All missions are complete.[/green]")
            return 0

        mission = load_mission(level)
        level["implementation_status"] = mission.get("implementation_status", level.get("implementation_status", "playable"))
        show_mission(level)
        show_menu()
        if level.get("implementation_status") != "playable":
            console.print("[yellow]This mission is currently scaffolded content. Briefing, hints, and docs are available, but service-specific setup/validation is not implemented yet.[/yellow]")
        command = read_command(level)
        command = COMMAND_ALIASES.get(command, command)

        if command in {"quit", "exit", "q"}:
            console.print("[yellow]Exiting AWSMissions.[/yellow]")
            return 0
        if command.startswith("aws ") or command.startswith("awslocal "):
            run_player_command(command, level)
            continue
        if command in {"help", "?"}:
            show_help()
            continue
        if command == "status":
            show_status(levels, progress.data)
            continue
        if command == "reset":
            os.system("clear")
            prepare_current_level(level)
            continue
        if command == "edit":
            target = editable_target(level)
            if target is None:
                os.system("clear")
                console.print("[yellow]This mission does not have an editable helper file yet.[/yellow]")
                continue
            console.print(f"[grey70]Opening {target.name} in your editor...[/grey70]")
            open_editor(target)
            continue
        if command == "hint":
            hint_number = progress.record_hint(str(level["id"]))
            hint_path = level_path(level) / f"hint-{hint_number}.txt"
            os.system("clear")
            if not hint_path.exists():
                show_deep_hint(build_detailed_hint(level, mission), hint_number)
                continue
            show_hint(hint_path.read_text(encoding="utf-8").strip(), hint_number)
            continue
        if command == "solution":
            show_text_file(level_path(level) / "solution.md", "Solution")
            continue
        if command == "debrief":
            show_text_file(level_path(level) / "debrief.md", "Debrief")
            continue
        if command == "next":
            next_level = move_to_next_level(levels, progress, level["id"])
            if next_level is None:
                os.system("clear")
                console.print("[yellow]You are already at the final mission.[/yellow]")
            else:
                os.system("clear")
                prepare_current_level(next_level)
            continue
        if command != "check":
            os.system("clear")
            console.print("[yellow]Unknown command. Type 'help' to see valid commands.[/yellow]")
            continue

        os.system("clear")
        start = time.time()
        result = validate_level(level_path(level))
        success = result.returncode == 0
        output = (result.stdout or "") + ("\n" + result.stderr if result.stderr else "")
        show_validation(success, output)
        if not success:
            continue

        first_completion = progress.add_completion(level["id"], int(level["xp"]), int(time.time() - start))
        if first_completion:
            console.print(f"[bright_green]+{level['xp']} XP awarded.[/bright_green]")
        maybe_award_module(levels, progress, level)
        next_level = move_to_next_level(levels, progress, level["id"])
        if next_level is None:
            console.print("[bold bright_green]All current MVP missions are complete.[/bold bright_green]")
            return 0
        prepare_current_level(next_level)


if __name__ == "__main__":
    raise SystemExit(main())
