#!/usr/bin/env python3
"""Player progress helpers."""

from __future__ import annotations

import json
from pathlib import Path


DEFAULT_PROGRESS = {
    "player_name": None,
    "total_xp": 0,
    "completed_levels": [],
    "current_level_id": 1,
    "module_certificates": [],
    "hint_state": {},
    "time_per_level": {},
}


class PlayerProgress:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.data = self._load()

    def _load(self) -> dict:
        if not self.path.exists():
            return DEFAULT_PROGRESS.copy()
        with self.path.open("r", encoding="utf-8") as handle:
            loaded = json.load(handle)
        merged = DEFAULT_PROGRESS.copy()
        merged.update(loaded)
        return merged

    def save(self) -> None:
        with self.path.open("w", encoding="utf-8") as handle:
            json.dump(self.data, handle, indent=2)

    def set_player_name(self, name: str) -> None:
        self.data["player_name"] = name
        self.save()

    def set_current_level(self, level_id: int) -> None:
        self.data["current_level_id"] = level_id
        self.save()

    def record_hint(self, level_key: str) -> int:
        current = int(self.data["hint_state"].get(level_key, 0)) + 1
        self.data["hint_state"][level_key] = current
        self.save()
        return current

    def add_completion(self, level_id: int, xp: int, elapsed_seconds: int) -> bool:
        completed = self.data["completed_levels"]
        first_completion = level_id not in completed
        if first_completion:
            completed.append(level_id)
            self.data["total_xp"] += xp
        self.data["time_per_level"][str(level_id)] = elapsed_seconds
        self.save()
        return first_completion

    def award_module_certificate(self, module_name: str) -> bool:
        certs = self.data["module_certificates"]
        if module_name in certs:
            return False
        certs.append(module_name)
        self.save()
        return True
