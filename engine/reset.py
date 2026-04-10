#!/usr/bin/env python3
"""Reset the LocalStack environment and seed a mission."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

from engine import localstack


AWS_ENV = {
    "AWS_DEFAULT_REGION": "us-east-1",
    "AWS_ACCESS_KEY_ID": "test",
    "AWS_SECRET_ACCESS_KEY": "test",
    "AWS_ENDPOINT_URL": "http://localhost:4566",
}


def mission_env() -> dict[str, str]:
    env = os.environ.copy()
    env.update(AWS_ENV)
    return env


def prepare_level(level_path: Path) -> None:
    localstack.reset()
    setup_script = level_path / "setup.sh"
    if setup_script.exists():
        subprocess.run(["bash", str(setup_script)], cwd=level_path, env=mission_env(), check=True)


def validate_level(level_path: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", str(level_path / "validate.sh")],
        cwd=level_path,
        env=mission_env(),
        capture_output=True,
        text=True,
        check=False,
    )
