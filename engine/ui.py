#!/usr/bin/env python3
"""Rich UI helpers for AWSMissions."""

from __future__ import annotations

from pathlib import Path

from rich import box
from rich.console import Console
from rich.markdown import Markdown
from rich.padding import Padding
from rich.panel import Panel
from rich.rule import Rule
from rich.table import Table
from rich.text import Text

console = Console()

ASCII_LOGO = """\
   ___ _       _______ __  ___ _         _
  /   | |     / / ___//  |/  /(_)_____  (_)___  ____  _____
 / /| | | /| / /\\__ \\/ /|_/ // // ___/ / // __ \\/ __ \\/ ___/
/ ___ | |/ |/ /___/ / /  / // /(__  ) / // /_/ / / / (__  )
/_/  |_|__/|__//____/_/  /_//_//____(_)_/ \\____/_/ /_/____/\
"""

_XP_THRESHOLDS = [
    (0,    200,  "Cloud Recruit"),
    (200,  500,  "Cloud Operator"),
    (500,  1000, "Cloud Engineer"),
    (1000, 2000, "Cloud Architect"),
    (2000, 4000, "Cloud Commander"),
    (4000, None, "Cloud Legend"),
]

_DIFFICULTY_COLOR = {
    "beginner":     "bright_green",
    "intermediate": "bright_yellow",
    "advanced":     "bright_red",
    "expert":       "red",
}


def _rank_info(xp: int) -> tuple[str, int, int | None, int]:
    """Return (rank_title, progress_value, progress_target, rank_floor)."""
    for lo, hi, title in _XP_THRESHOLDS:
        if hi is None or xp < hi:
            return title, xp, hi, lo
    last = _XP_THRESHOLDS[-1]
    return last[2], xp, None, last[0]


def _xp_bar(current: int, total: int | None, width: int = 24) -> Text:
    bar = Text()
    if total is None:
        bar.append("█" * width, style="bright_magenta")
        bar.append("  MAX", style="bright_magenta")
        return bar
    filled = min(width, int(current / total * width))
    bar.append("█" * filled, style="bright_cyan")
    bar.append("░" * (width - filled), style="grey30")
    bar.append(f"  {current}/{total}", style="grey50")
    return bar


def _difficulty_badge(difficulty: str) -> Text:
    color = _DIFFICULTY_COLOR.get(difficulty.lower(), "white")
    badge = Text()
    badge.append(f" {difficulty.upper()} ", style=f"bold {color} on grey15")
    return badge


def show_title(player_name: str, total_xp: int) -> None:
    rank, xp_progress, xp_target, rank_floor = _rank_info(total_xp)

    logo = Text(ASCII_LOGO, style="bold bright_cyan")

    sep = Text("  " + "─" * 46, style="grey23")

    meta = Text()
    meta.append("\n  AGENT    ", style="grey50")
    meta.append(player_name, style="bold white")
    meta.append("\n  RANK     ", style="grey50")
    meta.append(rank, style="bold bright_yellow")
    meta.append("\n  XP       ", style="grey50")
    meta.append(_xp_bar(xp_progress, xp_target))
    if xp_target is None:
        meta.append(f"   {total_xp} total", style="grey35")
    else:
        meta.append(f"   {total_xp - rank_floor} into rank", style="grey35")
    meta.append("\n")

    content = Text.assemble(logo, "\n", sep, meta)
    console.print(Panel(content, border_style="bright_cyan", box=box.HEAVY, padding=(0, 1)))
    console.print()


def show_status(levels: list[dict], progress: dict) -> None:
    completed = set(progress.get("completed_levels", []))
    certs = set(progress.get("module_certificates", []))

    # Group levels by module
    modules: dict[str, list[dict]] = {}
    for level in levels:
        modules.setdefault(level["module_name"], []).append(level)

    table = Table(box=box.SIMPLE_HEAD, show_edge=True, border_style="grey23", expand=False)
    table.add_column("  #", justify="right", style="grey50", no_wrap=True)
    table.add_column("Mission", style="white", min_width=28)
    table.add_column("XP", justify="right", style="bright_magenta", no_wrap=True)
    table.add_column("Difficulty", no_wrap=True)
    table.add_column("Status", no_wrap=True)
    table.add_column("Done", justify="center", no_wrap=True)

    for module_name, lvls in modules.items():
        playable = [l for l in lvls if l.get("implementation_status", "playable") != "scaffolded"]
        done_count = sum(1 for l in playable if l["id"] in completed)
        cert_mark = " [bright_yellow]CERT[/bright_yellow]" if module_name in certs else ""
        title_text = f"[bold bright_cyan]{lvls[0]['module_title']}[/bold bright_cyan]"
        prog_text = f"[grey50]{done_count}/{len(playable)} levels[/grey50]"
        table.add_section()
        table.add_row(f"[bold bright_cyan]{title_text}[/bold bright_cyan]", prog_text + cert_mark, "", "", "", "")

        for level in lvls:
            is_done = level["id"] in completed
            status = level.get("implementation_status", "playable")
            if status == "scaffolded":
                status_text = Text("coming soon", style="grey35 italic")
                name_style = "grey40"
                done_cell = Text("·", style="grey35")
            elif is_done:
                status_text = Text("complete", style="bright_green")
                name_style = "white"
                done_cell = Text("[bright_green]✓[/bright_green]")
            else:
                status_text = Text("available", style="bright_yellow")
                name_style = "white"
                done_cell = Text("")

            diff = level.get("difficulty", "beginner")
            diff_color = _DIFFICULTY_COLOR.get(diff.lower(), "white")
            diff_text = Text(diff, style=diff_color)

            table.add_row(
                str(level["id"]),
                Text(level["name"], style=name_style),
                str(level["xp"]) if status != "scaffolded" else "",
                diff_text if status != "scaffolded" else Text(""),
                status_text,
                done_cell,
            )

    console.print()
    console.print(Panel(table, title="[bold bright_cyan]Mission Status[/bold bright_cyan]",
                        border_style="bright_cyan", box=box.ROUNDED, padding=(0, 0)))
    console.print()


def show_mission(level: dict) -> None:
    diff = level.get("difficulty", "beginner")
    diff_color = _DIFFICULTY_COLOR.get(diff.lower(), "white")
    level_num = level.get("module_level_number", level["id"])

    # Header line
    header = Text()
    header.append(level["module_title"], style="bold bright_cyan")
    header.append("  ", style="")
    header.append(f"Level {level_num}", style="grey50")

    # Title
    title_text = Text(f"\n{level['name']}\n", style="bold white")

    # Description
    desc_text = Text(level["description"] + "\n", style="white")

    # Objective block
    obj_label = Text("OBJECTIVE  ", style="bold bright_green")
    obj_text = Text(level["objective"], style="white")

    # Footer metadata
    footer = Text("\n")
    footer.append(f"  {level['xp']} XP", style="bold bright_magenta")
    footer.append("   ", style="")
    footer.append(f"{diff.upper()}", style=f"bold {diff_color}")

    rule = Text("─" * 52, style="grey23")

    content = Text.assemble(
        "\n",
        header,
        title_text,
        desc_text,
        rule,
        "\n",
        obj_label, obj_text,
        footer,
        "\n",
    )

    console.print(Panel(
        content,
        title="[bold bright_cyan]Mission Briefing[/bold bright_cyan]",
        border_style="bright_cyan",
        box=box.HEAVY,
        padding=(0, 2),
    ))


def show_environment() -> None:
    rows = [
        ("AWS commands", "Run [bright_cyan]aws ...[/bright_cyan] directly in-game"),
        ("LocalStack", "Already configured — no setup needed"),
        ("Local files", "[grey70]policy.json[/grey70] etc. work from the level dir"),
        ("Example", "[grey50]aws iam put-role-policy --role-name ... --policy-document file://policy.json[/grey50]"),
    ]
    table = Table(box=None, show_header=False, padding=(0, 1))
    table.add_column(style="bright_yellow", no_wrap=True)
    table.add_column(style="white")
    for label, value in rows:
        table.add_row(label, value)

    console.print(Panel(
        table,
        title="[bold bright_yellow]Environment[/bold bright_yellow]",
        border_style="yellow",
        box=box.ROUNDED,
        padding=(0, 1),
    ))
    console.print()


def show_hint(content: str, number: int) -> None:
    body = Text("\n" + content + "\n", style="white")
    console.print(Panel(
        Text.assemble(body),
        title=f"[bold yellow]Hint {number}[/bold yellow]",
        border_style="yellow",
        box=box.ROUNDED,
        padding=(0, 2),
    ))


def show_deep_hint(content: str, number: int) -> None:
    console.print(Panel(
        Text("\n" + content + "\n", style="white"),
        title=f"[bold bright_magenta]Deep Hint {number}[/bold bright_magenta]",
        border_style="bright_magenta",
        box=box.HEAVY,
        padding=(0, 2),
    ))


def show_validation(success: bool, output: str) -> None:
    if success:
        heading = Text("\n  MISSION PASSED\n", style="bold bright_green")
        style = "bright_green"
        title = "[bold bright_green]Validation[/bold bright_green]"
    else:
        heading = Text("\n  MISSION FAILED\n", style="bold bright_red")
        style = "bright_red"
        title = "[bold bright_red]Validation[/bold bright_red]"

    body = Text(output.strip(), style="white") if output.strip() else Text("")
    rule = Text("  " + "─" * 48 + "\n", style="grey23")
    content = Text.assemble(heading, rule, "  ", body, "\n")

    console.print(Panel(
        content,
        title=title,
        border_style=style,
        box=box.HEAVY,
        padding=(0, 0),
    ))


def show_module_complete(certificate: str) -> None:
    banner_lines = [
        "",
        "  ★  MODULE COMPLETE  ★",
        "",
    ]
    banner = Text("\n".join(banner_lines), style="bold bright_yellow")
    rule = Text("  " + "─" * 48 + "\n\n", style="grey23")
    cert_text = Text(certificate, style="bright_cyan")
    content = Text.assemble(banner, rule, cert_text, "\n")

    console.print(Panel(
        content,
        title="[bold bright_yellow]Achievement Unlocked[/bold bright_yellow]",
        border_style="bright_yellow",
        box=box.HEAVY,
        padding=(0, 1),
    ))


def show_text_file(path: Path, title: str) -> None:
    if not path.exists():
        console.print(Panel(
            Text(f"\n  {title} is not available yet.\n", style="yellow italic"),
            border_style="yellow",
            box=box.ROUNDED,
        ))
        return
    console.print(Panel(
        Markdown(path.read_text(encoding="utf-8")),
        title=f"[bold white]{title}[/bold white]",
        border_style="grey50",
        box=box.ROUNDED,
        padding=(1, 2),
    ))


def show_help() -> None:
    table = Table(box=None, show_header=False, padding=(0, 2), expand=False)
    table.add_column(style="bold bright_cyan", no_wrap=True, min_width=12)
    table.add_column(style="white")
    table.add_column(style="bold bright_cyan", no_wrap=True, min_width=12)
    table.add_column(style="white")

    pairs = [
        ("check",    "run the validator",           "hint",     "show the next hint"),
        ("reset",    "rebuild the AWS environment",  "edit",     "open the helper file"),
        ("solution", "show the reference answer",    "debrief",  "show lesson summary"),
        ("status",   "show all missions",            "next",     "skip to next mission"),
        ("aws ...",  "run an AWS CLI command",        "quit",     "exit the game"),
    ]
    for c1, d1, c2, d2 in pairs:
        table.add_row(c1, d1, c2, d2)

    console.print(Panel(
        Padding(table, (1, 2)),
        title="[bold bright_cyan]Commands[/bold bright_cyan]",
        border_style="bright_cyan",
        box=box.ROUNDED,
    ))


def show_menu() -> None:
    items = [
        ("1", "check"), ("2", "hint"), ("3", "reset"), ("4", "edit"),
        ("5", "solution"), ("6", "debrief"), ("7", "status"),
        ("8", "next"), ("9", "help"), ("0", "quit"),
    ]
    line = Text()
    for key, name in items:
        line.append(f" {key}", style="bold bright_cyan")
        line.append(f"·{name} ", style="grey50")
    console.print(Rule(line, style="grey23"))
