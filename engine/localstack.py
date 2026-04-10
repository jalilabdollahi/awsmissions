#!/usr/bin/env python3
"""LocalStack lifecycle management."""

from __future__ import annotations

import json
import shutil
import subprocess
import time
import urllib.error
import urllib.request


LOCALSTACK_IMAGE = "localstack/localstack:3.8"
LOCALSTACK_CONTAINER = "awsmissions-localstack"
LOCALSTACK_PORT = "4566"
HEALTH_URL = "http://localhost:4566/_localstack/health"


def _run(args: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, capture_output=True, text=True, check=check)


def docker_available() -> bool:
    if shutil.which("docker") is None:
        return False
    result = subprocess.run(["docker", "version"], capture_output=True, text=True, check=False)
    return result.returncode == 0


def aws_cli_available() -> bool:
    if shutil.which("aws") is None:
        return False
    result = subprocess.run(["aws", "--version"], capture_output=True, text=True, check=False)
    return result.returncode == 0


def is_running() -> bool:
    result = subprocess.run(
        ["docker", "ps", "--filter", f"name={LOCALSTACK_CONTAINER}", "--format", "{{.Names}}"],
        capture_output=True,
        text=True,
        check=False,
    )
    return LOCALSTACK_CONTAINER in result.stdout.splitlines()


def ensure_container() -> None:
    inspect = subprocess.run(
        ["docker", "ps", "-a", "--filter", f"name={LOCALSTACK_CONTAINER}", "--format", "{{.Names}}"],
        capture_output=True,
        text=True,
        check=False,
    )
    if LOCALSTACK_CONTAINER in inspect.stdout.splitlines():
        _run(["docker", "rm", "-f", LOCALSTACK_CONTAINER], check=False)


def start() -> None:
    ensure_container()
    _run(
        [
            "docker",
            "run",
            "-d",
            "--name",
            LOCALSTACK_CONTAINER,
            "-p",
            f"{LOCALSTACK_PORT}:4566",
            "-v",
            "/var/run/docker.sock:/var/run/docker.sock",
            LOCALSTACK_IMAGE,
        ]
    )


def stop() -> None:
    _run(["docker", "rm", "-f", LOCALSTACK_CONTAINER], check=False)


def reset() -> None:
    stop()
    start()
    wait_ready()


def wait_ready(timeout: int = 60) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(HEALTH_URL, timeout=2) as response:
                data = json.loads(response.read().decode("utf-8"))
            # LocalStack 3.x returns {"services": {"s3": "available", ...}}
            # Any valid JSON response means LocalStack is up and accepting requests
            if "services" in data:
                return
        except (urllib.error.URLError, json.JSONDecodeError, TimeoutError, OSError):
            pass
        time.sleep(2)
    raise RuntimeError("LocalStack did not become healthy in time.")
