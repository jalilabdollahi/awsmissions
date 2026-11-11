#!/usr/bin/env python3
"""Flag missions that look generated from a shared template.

Every level must be written for its own scenario. This compares each pair of
levels file-by-file using token 4-gram shingles (Jaccard similarity) after
stripping comments, the shebang and the standard helper `source` line, and
reports pairs above the threshold. It also flags duplicate mission names,
descriptions and resource names reused verbatim across levels.

Usage:
  .venv/bin/python scripts/check_uniqueness.py                 # whole repo
  .venv/bin/python scripts/check_uniqueness.py --focus modules/module-1-iam
  .venv/bin/python scripts/check_uniqueness.py --threshold 0.5
"""

from __future__ import annotations

import argparse
import itertools
import re
from collections import defaultdict
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
FILES = ["setup.sh", "validate.sh", "solution.sh", "hint-1.txt", "hint-2.txt", "hint-3.txt", "solution.md", "debrief.md"]
BOILERPLATE = [
    re.compile(r"^#!.*$", re.M),
    re.compile(r"^\s*set -euo pipefail\s*$", re.M),
    re.compile(r"^\s*source .*aws_helpers\.sh.*$", re.M),
    re.compile(r"^\s*#.*$", re.M),
]
TOKEN = re.compile(r"[A-Za-z_][A-Za-z0-9_:\-\.]*|\d+|[^\sA-Za-z0-9]")


def normalize(text: str, shell: bool) -> list[str]:
    if shell:
        for pattern in BOILERPLATE:
            text = pattern.sub("", text)
    return TOKEN.findall(text.lower())


def shingles(tokens: list[str], n: int = 4) -> set[tuple[str, ...]]:
    if len(tokens) < n:
        return {tuple(tokens)} if tokens else set()
    return {tuple(tokens[i:i + n]) for i in range(len(tokens) - n + 1)}


def jaccard(a: set, b: set) -> float:
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--threshold", type=float, default=0.55)
    parser.add_argument("--focus", help="only report pairs involving levels under this path")
    args = parser.parse_args()

    levels = sorted(p.parent for p in (ROOT / "modules").glob("*/level-*/mission.yaml"))
    focus = (ROOT / args.focus).resolve() if args.focus else None
    data: dict[Path, dict[str, set]] = {}
    for level in levels:
        data[level] = {}
        for name in FILES:
            path = level / name
            if path.exists():
                data[level][name] = shingles(normalize(path.read_text(encoding="utf-8"), name.endswith(".sh")))

    findings = 0
    for a, b in itertools.combinations(levels, 2):
        if focus and not (str(a).startswith(str(focus)) or str(b).startswith(str(focus))):
            continue
        for name in FILES:
            if name in data[a] and name in data[b]:
                score = jaccard(data[a][name], data[b][name])
                if score >= args.threshold:
                    findings += 1
                    print(f"{score:.2f}  {name:12} {a.relative_to(ROOT)}  <->  {b.relative_to(ROOT)}")

    seen: dict[str, dict[str, list[str]]] = {"name": defaultdict(list), "description": defaultdict(list)}
    for level in levels:
        mission = yaml.safe_load((level / "mission.yaml").read_text(encoding="utf-8")) or {}
        for field in seen:
            value = str(mission.get(field, "")).strip().lower()
            if value:
                seen[field][value].append(str(level.relative_to(ROOT)))
    for field, values in seen.items():
        for value, where in values.items():
            if len(where) > 1 and (not focus or any(w.startswith(str(focus.relative_to(ROOT))) for w in where)):
                findings += 1
                print(f"duplicate mission {field}: {value[:60]!r} in {', '.join(where)}")

    print(f"\n{findings} finding(s) across {len(levels)} levels (threshold {args.threshold})")
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
