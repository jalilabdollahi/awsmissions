#!/usr/bin/env python3
"""Floci (local AWS emulator) lifecycle management.

Floci is a LocalStack-compatible emulator (https://github.com/floci-io/floci).
One container serves every mission; between missions we wipe its state through
the reset endpoint instead of recreating the container.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import time
import urllib.error
import urllib.request

FLOCI_IMAGE = os.environ.get("AWSMISSIONS_FLOCI_IMAGE", "floci/floci:2.4.0")
DEFAULT_PORT = 4566


class FlociError(RuntimeError):
    """Raised when the emulator cannot be started, reached, or reset."""


def port() -> int:
    return int(os.environ.get("AWSMISSIONS_PORT", DEFAULT_PORT))


def endpoint(p: int | None = None) -> str:
    return f"http://localhost:{p or port()}"


def container_name(p: int | None = None) -> str:
    p = p or port()
    return "awsmissions-floci" if p == DEFAULT_PORT else f"awsmissions-floci-{p}"


def _docker(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["docker", *args], capture_output=True, text=True, check=False)


def docker_available() -> bool:
    return shutil.which("docker") is not None and _docker("version").returncode == 0


def aws_cli_available() -> bool:
    if shutil.which("aws") is None:
        return False
    return subprocess.run(["aws", "--version"], capture_output=True, text=True, check=False).returncode == 0


def healthy(p: int | None = None) -> bool:
    try:
        with urllib.request.urlopen(f"{endpoint(p)}/_localstack/health", timeout=2) as response:
            return "services" in json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, json.JSONDecodeError, TimeoutError, OSError):
        return False


def _running_image(p: int) -> str | None:
    result = _docker("inspect", "--format", "{{.State.Running}} {{.Config.Image}}", container_name(p))
    if result.returncode != 0:
        return None
    running, _, image = result.stdout.strip().partition(" ")
    return image if running == "true" else None


def start(p: int | None = None) -> None:
    p = p or port()
    _docker("rm", "-f", container_name(p))
    result = _docker(
        "run", "-d",
        "--name", container_name(p),
        "-p", f"{p}:4566",
        "-v", "/var/run/docker.sock:/var/run/docker.sock",
        # Real IAM policy evaluation: the default `test` credentials act as the
        # account root, any other principal is checked against its policies.
        "-e", "FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED=true",
        FLOCI_IMAGE,
    )
    if result.returncode != 0:
        raise FlociError(f"Could not start Floci on port {p}: {result.stderr.strip()}")
    wait_ready(p)


def stop(p: int | None = None) -> None:
    _docker("rm", "-f", container_name(p))


def wait_ready(p: int | None = None, timeout: int = 90) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        if healthy(p):
            return
        time.sleep(1)
    raise FlociError(f"Floci did not become healthy on {endpoint(p)} within {timeout}s.")


def ensure_running(p: int | None = None) -> None:
    """Reuse a healthy container running the pinned image, otherwise (re)start it."""
    p = p or port()
    if _running_image(p) == FLOCI_IMAGE and healthy(p):
        return
    start(p)


def _leftover_stacks(p: int) -> bool:
    """Floci 2.4.0's reset endpoint keeps CloudFormation stacks and exports."""
    env = {**os.environ, "AWS_ACCESS_KEY_ID": "test", "AWS_SECRET_ACCESS_KEY": "test",
           "AWS_DEFAULT_REGION": "us-east-1", "AWS_PAGER": ""}
    for key in ("AWS_PROFILE", "AWS_SESSION_TOKEN"):
        env.pop(key, None)
    result = subprocess.run(
        ["aws", f"--endpoint-url={endpoint(p)}", "cloudformation", "describe-stacks",
         "--query", "length(Stacks)", "--output", "text"],
        capture_output=True, text=True, env=env, check=False, timeout=60,
    )
    return result.returncode != 0 or result.stdout.strip() not in ("0", "")


def reset_state(p: int | None = None) -> None:
    """Wipe every service's state. Falls back to a container restart."""
    p = p or port()
    ensure_running(p)
    for _ in range(3):
        try:
            request = urllib.request.Request(f"{endpoint(p)}/_floci/state/reset", data=b"", method="POST")
            with urllib.request.urlopen(request, timeout=30) as response:
                if json.loads(response.read().decode("utf-8")).get("status") == "OK":
                    if _leftover_stacks(p):
                        break  # only a fresh container clears CloudFormation
                    return
        except (urllib.error.URLError, json.JSONDecodeError, TimeoutError, OSError, subprocess.TimeoutExpired):
            pass
        time.sleep(1)
    start(p)
