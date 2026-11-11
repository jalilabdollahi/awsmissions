#!/usr/bin/env python3
"""Mission environment: credentials isolation, workspace, setup and validation."""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

from engine import floci

REPO_ROOT = Path(__file__).resolve().parent.parent
STATE_DIR = REPO_ROOT / ".awsmissions"
WORKSPACE_ROOT = REPO_ROOT / ".sandboxes"
SCRIPT_TIMEOUT = 600


class MissionError(RuntimeError):
    """Raised when a mission's setup cannot build its broken environment."""


def _isolated_aws_files() -> tuple[Path, Path]:
    """Config/credentials files that only know the emulator.

    Pointing the CLI at these means a player's real ~/.aws profiles can never
    be picked up by a mission command, even with --profile.
    """
    STATE_DIR.mkdir(exist_ok=True)
    config = STATE_DIR / "aws-config"
    credentials = STATE_DIR / "aws-credentials"
    config.write_text(f"[default]\nregion = us-east-1\noutput = json\nendpoint_url = {floci.endpoint()}\n", encoding="utf-8")
    credentials.write_text("[default]\naws_access_key_id = test\naws_secret_access_key = test\n", encoding="utf-8")
    return config, credentials


def mission_env(workdir: Path | None = None, mission_dir: Path | None = None) -> dict[str, str]:
    env = os.environ.copy()
    for key in ("AWS_PROFILE", "AWS_DEFAULT_PROFILE", "AWS_SESSION_TOKEN", "AWS_SECURITY_TOKEN", "AWS_ROLE_ARN",
                "AWS_WEB_IDENTITY_TOKEN_FILE", "AWS_CA_BUNDLE"):
        env.pop(key, None)
    config, credentials = _isolated_aws_files()
    env.update(
        {
            "AWS_CONFIG_FILE": str(config),
            "AWS_SHARED_CREDENTIALS_FILE": str(credentials),
            "AWS_DEFAULT_REGION": "us-east-1",
            "AWS_REGION": "us-east-1",
            "AWS_ACCESS_KEY_ID": "test",
            "AWS_SECRET_ACCESS_KEY": "test",
            "AWS_ENDPOINT_URL": floci.endpoint(),
            "AWS_PAGER": "",
            "AWSMISSIONS_ROOT": str(REPO_ROOT),
            "AWSMISSIONS_PORT": str(floci.port()),
        }
    )
    venv_bin = REPO_ROOT / ".venv" / "bin"
    if venv_bin.is_dir():
        env["PATH"] = f"{venv_bin}{os.pathsep}{env.get('PATH', '')}"
    if workdir is not None:
        env["WORKDIR"] = str(workdir)
    if mission_dir is not None:
        env["MISSION_DIR"] = str(mission_dir)
    return env


def prepare_workspace(level_path: Path, workdir: Path) -> Path:
    """Fresh copy of the level's workspace/ files for the player to edit."""
    if workdir.exists():
        shutil.rmtree(workdir)
    source = level_path / "workspace"
    if source.is_dir():
        shutil.copytree(source, workdir)
    else:
        workdir.mkdir(parents=True)
    return workdir


def _services(level_path: Path) -> list[str]:
    try:
        import yaml
        mission = yaml.safe_load((level_path / "mission.yaml").read_text(encoding="utf-8")) or {}
        return [str(x) for x in mission.get("services", [])]
    except Exception:  # an unreadable mission must not block the reset
        return []


def prepare_level(level_path: Path, workdir: Path) -> None:
    """Wipe the emulator, reset the workspace and seed the broken environment."""
    floci.reset_state()
    floci.remember_services(_services(level_path))
    prepare_workspace(level_path, workdir)
    setup_script = level_path / "setup.sh"
    if not setup_script.exists():
        return
    try:
        result = subprocess.run(
            ["bash", str(setup_script)],
            cwd=level_path,
            env=mission_env(workdir, level_path),
            capture_output=True,
            text=True,
            timeout=SCRIPT_TIMEOUT,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise MissionError(f"setup.sh timed out after {SCRIPT_TIMEOUT}s") from exc
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()[-1500:]
        raise MissionError(f"setup.sh failed (exit {result.returncode}):\n{detail}")


def validate_level(level_path: Path, workdir: Path) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            ["bash", str(level_path / "validate.sh")],
            cwd=level_path,
            env=mission_env(workdir, level_path),
            capture_output=True,
            text=True,
            timeout=SCRIPT_TIMEOUT,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(args=["validate.sh"], returncode=124, stdout="", stderr=f"Validation timed out after {SCRIPT_TIMEOUT}s.")
