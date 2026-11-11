#!/usr/bin/env python3
"""End-to-end test for missions against a live Floci emulator.

For every level it checks, in a freshly reset emulator:
  1. static rules (required files, mission.yaml fields, hints, bash 3.2 traps)
  2. setup.sh succeeds                       -> the broken world can be built
  3. validate.sh FAILS right after setup      -> the level is not pre-solved
  4. solution.sh succeeds (cwd = workspace)   -> the reference fix works
  5. validate.sh PASSES after the solution    -> the validator accepts the fix
  6. setup.sh is repeatable after a reset      -> `reset` works for players

Usage:
  .venv/bin/python scripts/test_levels.py modules/module-1-iam            # whole module
  .venv/bin/python scripts/test_levels.py modules/module-1-iam/level-2-*  # one level
  AWSMISSIONS_PORT=4601 .venv/bin/python scripts/test_levels.py ...       # own emulator
Options: --static-only, --keep-going (default stops at nothing; always runs all), -v
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from engine import floci  # noqa: E402
from engine.reset import mission_env, prepare_workspace  # noqa: E402

REQUIRED_FILES = ["mission.yaml", "setup.sh", "validate.sh", "solution.sh", "solution.md", "debrief.md",
                  "hint-1.txt", "hint-2.txt", "hint-3.txt"]
MISSION_KEYS = {"name", "description", "objective", "xp", "difficulty", "expected_time", "concepts", "services"}
DIFFICULTIES = {"beginner", "intermediate", "advanced", "expert"}
BASH32_TRAPS = [
    (re.compile(r"\bmapfile\b|\breadarray\b"), "mapfile/readarray (bash 4+)"),
    (re.compile(r"\bdeclare\s+-A\b|\blocal\s+-A\b"), "associative arrays (bash 4+)"),
    (re.compile(r"\$\{[A-Za-z_][A-Za-z0-9_]*(,,|\^\^)"), "${var,,}/${var^^} case conversion (bash 4+)"),
    (re.compile(r"&>>"), "&>> redirection (bash 4+)"),
    (re.compile(r"\bwait\s+-n\b"), "wait -n (bash 4.3+)"),
    (re.compile(r"(?<![\w-])(sed\s+-i\s+['\"])"), "sed -i without a backup suffix argument (GNU-only form); use a temp file or python"),
    (re.compile(r"\bgrep\s+(-\w*P|--perl-regexp)"), "grep -P (not available on macOS)"),
    (re.compile(r"\bdate\s+-d\b"), "date -d (GNU-only)"),
    (re.compile(r"\breadlink\s+-f\b"), "readlink -f (GNU-only on older macOS)"),
]


def static_checks(level: Path) -> list[str]:
    problems: list[str] = []
    for name in REQUIRED_FILES:
        path = level / name
        if not path.exists():
            problems.append(f"missing {name}")
        elif not path.read_text(encoding="utf-8").strip():
            problems.append(f"empty {name}")
    mission_path = level / "mission.yaml"
    if mission_path.exists():
        mission = yaml.safe_load(mission_path.read_text(encoding="utf-8")) or {}
        missing = MISSION_KEYS - set(mission)
        if missing:
            problems.append(f"mission.yaml missing keys: {', '.join(sorted(missing))}")
        if mission.get("difficulty") not in DIFFICULTIES:
            problems.append(f"mission.yaml difficulty must be one of {sorted(DIFFICULTIES)}")
        if not isinstance(mission.get("xp"), int):
            problems.append("mission.yaml xp must be an integer")
        if mission.get("implementation_status"):
            problems.append("mission.yaml must not contain implementation_status")
    for name in ("setup.sh", "validate.sh", "solution.sh"):
        path = level / name
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        if not text.startswith("#!/usr/bin/env bash"):
            problems.append(f"{name} must start with #!/usr/bin/env bash")
        for pattern, label in BASH32_TRAPS:
            if pattern.search(text):
                problems.append(f"{name}: {label}")
        if "localhost:4566" in text:
            problems.append(f"{name}: hard-coded localhost:4566 (use aws_local / $AWS_ENDPOINT_URL)")
    validate = level / "validate.sh"
    if validate.exists():
        text = validate.read_text(encoding="utf-8")
        # Messages to the player may mention file names; only code may not read them.
        code = "\n".join(line for line in text.splitlines()
                         if not re.match(r"\s*(echo|printf|#)", line))
        workspace = level / "workspace"
        if workspace.is_dir():
            for f in workspace.rglob("*"):
                if f.is_file() and re.search(rf"(?<![\w$/{{]){re.escape(f.name)}\b", code) and "$WORKDIR" not in code:
                    problems.append(f"validate.sh reads workspace file {f.name} from the level dir; validate real AWS state instead")
        if "aws_local" not in text and "aws_as_" not in text and "aws_with_creds" not in text and "curl" not in text:
            problems.append("validate.sh never queries the emulator")
    return problems


def run(script: Path, cwd: Path, workdir: Path, level: Path, timeout: int = 600) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(["bash", str(script)], cwd=cwd, env=mission_env(workdir, level),
                              capture_output=True, text=True, timeout=timeout, check=False)
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess([str(script)], 124, "", f"timed out after {timeout}s")


def tail(result: subprocess.CompletedProcess[str], lines: int = 12) -> str:
    text = ((result.stdout or "") + "\n" + (result.stderr or "")).strip().splitlines()
    return "\n".join("      | " + line for line in text[-lines:])


def dynamic_checks(level: Path, verbose: bool) -> list[str]:
    problems: list[str] = []
    with tempfile.TemporaryDirectory(prefix="awsm-") as tmp:
        workdir = Path(tmp) / "workspace"
        floci.reset_state()
        prepare_workspace(level, workdir)
        r = run(level / "setup.sh", level, workdir, level)
        if r.returncode != 0:
            return [f"setup.sh failed (exit {r.returncode})\n{tail(r)}"]
        r = run(level / "validate.sh", level, workdir, level)
        if r.returncode == 0:
            problems.append(f"validate.sh PASSES on the broken state — level is pre-solved\n{tail(r)}")
        elif verbose:
            print(f"    broken-state message:\n{tail(r, 4)}")
        if not (r.stdout or "").strip():
            problems.append("validate.sh prints nothing on failure — players need a reason")
        r = run(level / "solution.sh", workdir, workdir, level)
        if r.returncode != 0:
            problems.append(f"solution.sh failed (exit {r.returncode})\n{tail(r)}")
            return problems
        r = run(level / "validate.sh", level, workdir, level)
        if r.returncode != 0:
            problems.append(f"validate.sh FAILS after solution.sh\n{tail(r)}")
        # A player hitting `reset` gets a wiped emulator and a fresh workspace.
        floci.reset_state()
        prepare_workspace(level, workdir)
        r = run(level / "setup.sh", level, workdir, level)
        if r.returncode != 0:
            problems.append(f"setup.sh is not repeatable after reset (exit {r.returncode})\n{tail(r)}")
    return problems


def expand(targets: list[str]) -> list[Path]:
    levels: list[Path] = []
    for target in targets:
        for path in sorted(ROOT.glob(target) if any(c in target for c in "*?[") else [ROOT / target]):
            path = path.resolve()
            if (path / "mission.yaml").exists() or path.name.startswith("level-"):
                levels.append(path)
            elif path.is_dir():
                levels.extend(sorted((p for p in path.iterdir() if p.is_dir() and p.name.startswith("level-")),
                                     key=lambda p: int(re.match(r"level-(\d+)", p.name).group(1))))
    return levels


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("targets", nargs="+")
    parser.add_argument("--static-only", action="store_true")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()

    levels = expand(args.targets)
    if not levels:
        print("No levels matched.")
        return 2
    if not args.static_only:
        floci.ensure_running()
        print(f"Floci {floci.FLOCI_IMAGE} on {floci.endpoint()}")

    failures = 0
    for level in levels:
        start = time.time()
        rel = level.relative_to(ROOT)
        problems = static_checks(level)
        if not problems and not args.static_only:
            problems = dynamic_checks(level, args.verbose)
        status = "PASS" if not problems else "FAIL"
        print(f"[{status}] {rel}  ({time.time() - start:.1f}s)")
        for problem in problems:
            print(f"    - {problem}")
        failures += bool(problems)
    print(f"\n{len(levels) - failures}/{len(levels)} levels passed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
