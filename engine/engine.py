#!/usr/bin/env python3
"""AWSMissions main game loop."""

from __future__ import annotations

import json
import os
import shlex
import subprocess
import sys
import time
from pathlib import Path

try:
    import readline
except ImportError:  # pragma: no cover - readline is missing on some platforms
    readline = None

import yaml
from rich.prompt import Prompt

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from engine import floci
from engine.certificate import render_certificate, save_certificate
from engine.player import PlayerProgress
from engine.reset import WORKSPACE_ROOT, MissionError, mission_env, prepare_level, prepare_workspace, validate_level
from engine.ui import (
    console,
    show_deep_hint,
    show_environment,
    show_error,
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
    "exit": "quit",
    "e": "edit",
    "?": "help",
    "sh": "shell",
}
COMMAND_NAMES = ["check", "hint", "reset", "edit", "solution", "debrief", "status", "next", "help", "quit", "shell", "files", "aws"]


# ─── Level registry ───────────────────────────────────────────────────────────

def load_levels() -> list[dict]:
    with LEVELS_PATH.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    levels: list[dict] = []
    for module in payload["modules"]:
        for level in module["levels"]:
            mission = level["mission"]
            levels.append(
                {
                    "key": level["key"],
                    "number": len(levels) + 1,
                    "module_level_number": level["number"],
                    "name": mission["name"],
                    "description": mission.get("description", ""),
                    "objective": mission.get("objective", ""),
                    "xp": int(mission.get("xp", 0)),
                    "difficulty": mission.get("difficulty", "beginner"),
                    "module_name": module["name"],
                    "module_title": module["title"],
                    "path": level["path"],
                }
            )
    return levels


def level_by_key(levels: list[dict], key: str | None) -> dict | None:
    return next((level for level in levels if level["key"] == key), None)


def level_path(level: dict) -> Path:
    return REPO_ROOT / level["path"]


def workspace_path(level: dict) -> Path:
    return WORKSPACE_ROOT / level["key"]


def ensure_workspace(level: dict) -> Path:
    workdir = workspace_path(level)
    if not workdir.exists():
        prepare_workspace(level_path(level), workdir)
    return workdir


def workspace_files(level: dict) -> list[Path]:
    workdir = ensure_workspace(level)
    return sorted(p for p in workdir.rglob("*") if p.is_file() and not p.name.startswith("."))


# ─── Player input ─────────────────────────────────────────────────────────────

def configure_readline(level: dict) -> None:
    if readline is None:
        return
    workdir = ensure_workspace(level)

    def completer(text: str, state: int) -> str | None:
        buffer = readline.get_line_buffer()
        if len(buffer.split()) <= 1 and not buffer.endswith(" "):
            candidates = COMMAND_NAMES
        else:
            names = [str(p.relative_to(workdir)) for p in workdir.rglob("*") if p.is_file()]
            candidates = names + [f"file://{n}" for n in names] + [f"fileb://{n}" for n in names]
        matches = sorted(c for c in set(candidates) if c.startswith(text))
        return matches[state] if state < len(matches) else None

    readline.set_completer_delims(" \t\n")
    if "libedit" in (readline.__doc__ or ""):
        readline.parse_and_bind("bind ^I rl_complete")
    else:
        readline.parse_and_bind("tab: complete")
    readline.set_completer(completer)


def read_command(level: dict) -> str:
    configure_readline(level)
    command = Prompt.ask("[bold bright_cyan]awsmissions[/bold bright_cyan]").strip()
    while command.endswith("\\"):
        command = f"{command[:-1].rstrip()} {Prompt.ask('...').strip()}".strip()
    lowered = command.lower()
    if lowered in COMMAND_ALIASES:
        return COMMAND_ALIASES[lowered]
    if lowered in COMMAND_NAMES:
        return lowered
    return command


def clear() -> None:
    console.clear()


def run_aws_command(raw_command: str, level: dict) -> None:
    command = raw_command.strip()
    if command.startswith("awslocal "):
        command = "aws " + command[len("awslocal "):]
    try:
        args = shlex.split(command)
    except ValueError as exc:
        show_error(f"Could not parse command: {exc}")
        return
    # Pin the endpoint explicitly so older CLIs that ignore AWS_ENDPOINT_URL
    # still talk to the emulator and never to a real AWS account.
    if not any(arg == "--endpoint-url" or arg.startswith("--endpoint-url=") for arg in args):
        args.insert(1, f"--endpoint-url={floci.endpoint()}")
    workdir = ensure_workspace(level)
    clear()
    console.print(f"[grey50]$ {command}[/grey50]  [grey35](in {workdir.relative_to(REPO_ROOT)})[/grey35]")
    try:
        subprocess.run(args, cwd=workdir, env=mission_env(workdir, level_path(level)), check=False)
    except KeyboardInterrupt:
        console.print("\n[yellow]Command interrupted.[/yellow]")


def run_shell_command(raw_command: str, level: dict) -> None:
    """`!cmd` runs a one-off shell command in the mission workspace."""
    workdir = ensure_workspace(level)
    clear()
    console.print(f"[grey50]$ {raw_command}[/grey50]  [grey35](in {workdir.relative_to(REPO_ROOT)})[/grey35]")
    try:
        subprocess.run(["bash", "-c", raw_command], cwd=workdir, env=mission_env(workdir, level_path(level)), check=False)
    except KeyboardInterrupt:
        console.print("\n[yellow]Command interrupted.[/yellow]")


def open_shell(level: dict) -> None:
    workdir = ensure_workspace(level)
    env = mission_env(workdir, level_path(level))
    env["PS1"] = "(awsmissions) \\W $ "
    shell = os.environ.get("SHELL", "/bin/bash")
    clear()
    console.print(
        "[bright_cyan]Mission shell[/bright_cyan] — aws commands here talk to the local emulator only. "
        "Type [bold]exit[/bold] to return to the game."
    )
    try:
        subprocess.run([shell], cwd=workdir, env=env, check=False)
    except (FileNotFoundError, KeyboardInterrupt):
        subprocess.run(["/bin/bash"], cwd=workdir, env=env, check=False)
    clear()


def open_editor(path: Path) -> None:
    editor = os.environ.get("VISUAL") or os.environ.get("EDITOR") or "nano"
    try:
        subprocess.run([*shlex.split(editor), str(path)], check=False)
    except FileNotFoundError:
        show_error(f"Editor '{editor}' was not found. Set $EDITOR (for example: export EDITOR=nano).")


def edit_command(level: dict, argument: str) -> None:
    files = workspace_files(level)
    if not files:
        clear()
        console.print("[yellow]This mission has no workspace files to edit. Use aws commands directly.[/yellow]")
        return
    workdir = workspace_path(level)
    target: Path | None = None
    if argument:
        target = next((f for f in files if str(f.relative_to(workdir)) == argument or f.name == argument), None)
        if target is None:
            show_error(f"No workspace file named '{argument}'.")
            return
    elif len(files) == 1:
        target = files[0]
    else:
        clear()
        for index, path in enumerate(files, start=1):
            console.print(f"  [bright_cyan]{index}[/bright_cyan]  {path.relative_to(workdir)}")
        choice = Prompt.ask("Which file?", default="1").strip()
        if choice.isdigit() and 1 <= int(choice) <= len(files):
            target = files[int(choice) - 1]
        else:
            target = next((f for f in files if str(f.relative_to(workdir)) == choice), None)
        if target is None:
            show_error("No such file.")
            return
    open_editor(target)
    clear()
    console.print(f"[grey70]Saved {target.relative_to(workdir)}. Apply it with an aws command (for example file://{target.relative_to(workdir)}).[/grey70]")


def list_files(level: dict) -> None:
    clear()
    files = workspace_files(level)
    workdir = workspace_path(level)
    console.print(f"[grey50]Workspace: {workdir.relative_to(REPO_ROOT)}[/grey50]")
    if not files:
        console.print("  [grey50](empty)[/grey50]")
    for path in files:
        console.print(f"  {path.relative_to(workdir)}")


# ─── Progression ──────────────────────────────────────────────────────────────

def module_completed(levels: list[dict], progress: PlayerProgress, module_name: str) -> bool:
    keys = {level["key"] for level in levels if level["module_name"] == module_name}
    return bool(keys) and keys.issubset(set(progress.data["completed_levels"]))


def first_incomplete_level(levels: list[dict], progress: PlayerProgress) -> dict | None:
    return next((level for level in levels if not progress.is_completed(level["key"])), None)


def current_level(progress: PlayerProgress, levels: list[dict]) -> dict | None:
    return level_by_key(levels, progress.data.get("current_level")) or first_incomplete_level(levels, progress) or (levels[-1] if levels else None)


def next_level_after(levels: list[dict], key: str) -> dict | None:
    for index, level in enumerate(levels):
        if level["key"] == key:
            return levels[index + 1] if index + 1 < len(levels) else None
    return None


def load_mission(level: dict) -> dict:
    with (level_path(level) / "mission.yaml").open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle) or {}


def build_detailed_hint(level: dict, mission: dict) -> str:
    solution_path = level_path(level) / "solution.md"
    excerpt: list[str] = []
    if solution_path.exists():
        capture = False
        for line in solution_path.read_text(encoding="utf-8").splitlines():
            if line.startswith("```"):
                if capture:
                    break
                capture = True
                continue
            if capture and line.strip():
                excerpt.append(line.rstrip())
            if len(excerpt) >= 8:
                break
    parts = [
        "You have used all the standard hints. Here is a more direct nudge.",
        "",
        f"Target: {mission.get('objective', level.get('objective', ''))}",
    ]
    if excerpt:
        parts += ["", "Command shape to start from:", *excerpt]
    else:
        parts += ["", "Compare the current resource configuration with the objective, then apply the matching update."]
    parts += ["", "For the full reference answer use `solution` (key 5)."]
    return "\n".join(parts)


def maybe_award_module(levels: list[dict], progress: PlayerProgress, level: dict) -> None:
    if not module_completed(levels, progress, level["module_name"]):
        return
    if not progress.award_module_certificate(level["module_name"]):
        return
    cert = render_certificate(level["module_title"], progress.data.get("player_name") or "Cloud Engineer")
    save_certificate(REPO_ROOT, level["module_name"], cert)
    show_module_complete(cert)


class Session:
    """Tracks the level that is currently seeded in the emulator."""

    def __init__(self) -> None:
        self.started_at = time.time()
        self.ready = False

    def prepare(self, level: dict) -> bool:
        console.print(f"[grey70]Resetting the emulator and seeding “{level['name']}”...[/grey70]")
        try:
            prepare_level(level_path(level), workspace_path(level))
        except (MissionError, floci.FlociError) as exc:
            self.ready = False
            show_error(f"Could not prepare this mission.\n\n{exc}\n\nType `reset` to try again or `next` to skip it.")
            return False
        self.started_at = time.time()
        self.ready = True
        return True


def ensure_player_name(progress: PlayerProgress) -> None:
    if progress.data.get("player_name"):
        return
    name = Prompt.ask("Choose your agent name", default="Cloud Engineer").strip() or "Cloud Engineer"
    progress.set_player_name(name)


def ensure_prerequisites() -> bool:
    missing = [name for name, ok in (("Docker (running)", floci.docker_available()), ("AWS CLI", floci.aws_cli_available())) if not ok]
    if missing:
        console.print(f"[red]Missing prerequisites:[/red] {', '.join(missing)}")
        return False
    return True


# ─── Main loop ────────────────────────────────────────────────────────────────

def handle(command: str, level: dict, levels: list[dict], progress: PlayerProgress, session: Session, mission: dict) -> bool:
    """Run one player command. Returns False when the game should exit."""
    verb, _, argument = command.partition(" ")
    if verb == "quit":
        console.print("[yellow]Exiting AWSMissions. The emulator keeps running; `./play.sh --stop` stops it.[/yellow]")
        return False
    if not command:
        clear()
        return True
    if command.startswith("!"):
        run_shell_command(command[1:].strip(), level)
    elif verb in {"aws", "awslocal"}:
        run_aws_command(command, level)
    elif verb == "shell":
        open_shell(level)
    elif verb == "help":
        clear()
        show_help()
    elif verb == "status":
        clear()
        show_status(levels, progress.data)
    elif verb == "files":
        list_files(level)
    elif verb == "reset":
        clear()
        session.prepare(level)
    elif verb == "edit":
        edit_command(level, argument.strip())
    elif verb == "hint":
        clear()
        number = progress.record_hint(level["key"])
        hint_path = level_path(level) / f"hint-{number}.txt"
        if hint_path.exists():
            show_hint(hint_path.read_text(encoding="utf-8").strip(), number)
        else:
            show_deep_hint(build_detailed_hint(level, mission), number)
    elif verb == "solution":
        clear()
        show_text_file(level_path(level) / "solution.md", "Solution")
    elif verb == "debrief":
        clear()
        show_text_file(level_path(level) / "debrief.md", "Debrief")
    elif verb == "next":
        clear()
        upcoming = next_level_after(levels, level["key"])
        if upcoming is None:
            console.print("[yellow]You are already at the final mission.[/yellow]")
        else:
            progress.set_current_level(upcoming["key"])
            session.prepare(upcoming)
    elif verb == "check":
        clear()
        if not session.ready:
            show_error("This mission's environment is not ready. Type `reset` first.")
            return True
        console.print("[grey70]Validating...[/grey70]")
        result = validate_level(level_path(level), workspace_path(level))
        success = result.returncode == 0
        output = (result.stdout or "") + (f"\n{result.stderr}" if result.stderr and not success else "")
        show_validation(success, output)
        if success:
            if progress.add_completion(level["key"], level["xp"], int(time.time() - session.started_at)):
                console.print(f"[bright_green]+{level['xp']} XP awarded.[/bright_green]")
            maybe_award_module(levels, progress, level)
            upcoming = next_level_after(levels, level["key"])
            if upcoming is None:
                console.print("[bold bright_green]Every mission is complete. Outstanding work.[/bold bright_green]")
                return False
            Prompt.ask("[grey50]Press Enter for the next mission[/grey50]", default="", show_default=False)
            clear()
            progress.set_current_level(upcoming["key"])
            session.prepare(upcoming)
    else:
        clear()
        console.print("[yellow]Unknown command. Type `help` to see what you can do.[/yellow]")
    return True


def main() -> int:
    if not LEVELS_PATH.exists():
        console.print("[red]levels.json is missing. Run ./install.sh first.[/red]")
        return 1
    if not ensure_prerequisites():
        return 1
    levels = load_levels()
    if not levels:
        console.print("[red]No levels found.[/red]")
        return 1

    progress = PlayerProgress(PROGRESS_PATH, [level["key"] for level in levels])
    ensure_player_name(progress)
    clear()
    show_title(progress.data.get("player_name") or "Cloud Engineer", progress.data.get("total_xp", 0))
    show_environment()

    console.print(f"[grey70]Starting the local AWS emulator (Floci) on {floci.endpoint()}...[/grey70]")
    try:
        floci.ensure_running()
    except floci.FlociError as exc:
        console.print(f"[red]{exc}[/red]")
        return 1

    session = Session()
    level = current_level(progress, levels)
    progress.set_current_level(level["key"])
    session.prepare(level)

    while True:
        level = current_level(progress, levels)
        mission = load_mission(level)
        show_mission(level, completed=progress.is_completed(level["key"]))
        show_menu()
        try:
            command = read_command(level)
            if not handle(command, level, levels, progress, session, mission):
                return 0
        except KeyboardInterrupt:
            console.print("\n[yellow]Exiting AWSMissions.[/yellow]")
            return 0
        except EOFError:
            return 0


if __name__ == "__main__":
    raise SystemExit(main())
