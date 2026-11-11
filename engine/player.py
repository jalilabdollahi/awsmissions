#!/usr/bin/env python3
"""Player progress helpers.

Levels are identified by their stable key ("module-1-iam/level-2-deny-effect"),
never by their position, so adding or reordering levels keeps progress intact.
"""

from __future__ import annotations

import copy
import json
from pathlib import Path

DEFAULT_PROGRESS = {
    "version": 2,
    "player_name": None,
    "total_xp": 0,
    "completed_levels": [],
    "current_level": None,
    "module_certificates": [],
    "hint_state": {},
    "time_per_level": {},
}


class PlayerProgress:
    def __init__(self, path: Path, level_keys_in_order: list[str] | None = None) -> None:
        self.path = path
        self.data = self._load(level_keys_in_order or [])

    def _load(self, keys: list[str]) -> dict:
        merged = copy.deepcopy(DEFAULT_PROGRESS)
        if not self.path.exists():
            return merged
        try:
            with self.path.open("r", encoding="utf-8") as handle:
                loaded = json.load(handle)
        except (OSError, json.JSONDecodeError):
            backup = self.path.with_suffix(".json.corrupt")
            self.path.replace(backup)
            return merged
        if loaded.get("version") != 2:
            loaded = self._migrate_v1(loaded, keys)
        merged.update(loaded)
        return merged

    @staticmethod
    def _migrate_v1(old: dict, keys: list[str]) -> dict:
        """v1 stored 1-based positions; map the ones that still exist to keys."""

        def key_for(position) -> str | None:
            try:
                index = int(position) - 1
            except (TypeError, ValueError):
                return None
            return keys[index] if 0 <= index < len(keys) else None

        completed = [k for k in (key_for(p) for p in old.get("completed_levels", [])) if k]
        return {
            "version": 2,
            "player_name": old.get("player_name"),
            "total_xp": old.get("total_xp", 0),
            "completed_levels": completed,
            "current_level": key_for(old.get("current_level_id")),
            "module_certificates": old.get("module_certificates", []),
            "hint_state": {k: v for k, v in ((key_for(p), n) for p, n in old.get("hint_state", {}).items()) if k},
            "time_per_level": {k: v for k, v in ((key_for(p), n) for p, n in old.get("time_per_level", {}).items()) if k},
        }

    def save(self) -> None:
        tmp = self.path.with_suffix(".json.tmp")
        with tmp.open("w", encoding="utf-8") as handle:
            json.dump(self.data, handle, indent=2)
        tmp.replace(self.path)

    def set_player_name(self, name: str) -> None:
        self.data["player_name"] = name
        self.save()

    def set_current_level(self, key: str) -> None:
        self.data["current_level"] = key
        self.save()

    def is_completed(self, key: str) -> bool:
        return key in self.data["completed_levels"]

    def record_hint(self, key: str) -> int:
        current = int(self.data["hint_state"].get(key, 0)) + 1
        self.data["hint_state"][key] = current
        self.save()
        return current

    def add_completion(self, key: str, xp: int, elapsed_seconds: int) -> bool:
        completed = self.data["completed_levels"]
        first_completion = key not in completed
        if first_completion:
            completed.append(key)
            self.data["total_xp"] += xp
        best = self.data["time_per_level"].get(key)
        if best is None or elapsed_seconds < best:
            self.data["time_per_level"][key] = elapsed_seconds
        self.save()
        return first_completion

    def award_module_certificate(self, module_name: str) -> bool:
        certs = self.data["module_certificates"]
        if module_name in certs:
            return False
        certs.append(module_name)
        self.save()
        return True
