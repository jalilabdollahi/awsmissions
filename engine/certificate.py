#!/usr/bin/env python3
"""Certificate rendering for completed AWS modules."""

from __future__ import annotations

from pathlib import Path


def render_certificate(module_title: str, player_name: str) -> str:
    border = "=" * 54
    return "\n".join(
        [
            border,
            "                AWSMISSIONS CERTIFICATE",
            border,
            f"Awarded to: {player_name}",
            f"For completing: {module_title}",
            "Achievement: Restored order to a broken AWS environment",
            border,
        ]
    )


def save_certificate(repo_root: Path, module_name: str, content: str) -> Path:
    cert_dir = repo_root / "certificates"
    cert_dir.mkdir(parents=True, exist_ok=True)
    output = cert_dir / f"{module_name}.txt"
    output.write_text(content + "\n", encoding="utf-8")
    return output
