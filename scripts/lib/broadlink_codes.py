"""Named IR/RF code storage for openclaw-broadlink."""

from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from broadlink_core import codes_dir

SLUG_RE = re.compile(r"^[a-z0-9][a-z0-9_\-]{0,63}$")


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def validate_code_record(rec: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    name = rec.get("name") or rec.get("id")
    if not name or not SLUG_RE.match(str(name)):
        errors.append("invalid_name")
    media = rec.get("media")
    if media not in ("ir", "rf"):
        errors.append("invalid_media")
    if rec.get("encoding", "broadlink_base64") != "broadlink_base64":
        errors.append("unsupported_encoding")
    if not rec.get("payload"):
        errors.append("missing_payload")
    if rec.get("safety_class") not in ("low", "high", None):
        errors.append("invalid_safety_class")
    return errors


def code_path(name: str, root: Path | None = None) -> Path:
    return (root or codes_dir()) / f"{name}.json"


def save_code(rec: dict[str, Any], root: Path | None = None) -> Path:
    errs = validate_code_record(rec)
    if errs:
        raise ValueError(",".join(errs))
    name = str(rec.get("name") or rec["id"])
    rec = {
        "id": name,
        "name": name,
        "media": rec["media"],
        "encoding": rec.get("encoding", "broadlink_base64"),
        "payload": rec["payload"],
        "device": rec.get("device") or "rm-max",
        "safety_class": rec.get("safety_class") or "low",
        "aliases": list(rec.get("aliases") or []),
        "learned_at": rec.get("learned_at") or utc_now_iso(),
        "notes": rec.get("notes") or "",
    }
    root = root or codes_dir()
    root.mkdir(parents=True, exist_ok=True)
    path = code_path(name, root)
    path.write_text(json.dumps(rec, indent=2) + "\n", encoding="utf-8")
    return path


def load_code(name: str, root: Path | None = None) -> dict[str, Any]:
    path = code_path(name, root)
    if not path.is_file():
        # alias scan
        for p in (root or codes_dir()).glob("*.json"):
            try:
                data = json.loads(p.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                continue
            aliases = {str(data.get("name", "")), str(data.get("id", ""))}
            aliases |= {str(a) for a in (data.get("aliases") or [])}
            if name in aliases:
                return data
        raise FileNotFoundError(f"unknown_code:{name}")
    return json.loads(path.read_text(encoding="utf-8"))


def list_codes(root: Path | None = None) -> list[dict[str, Any]]:
    root = root or codes_dir()
    if not root.is_dir():
        return []
    out: list[dict[str, Any]] = []
    for p in sorted(root.glob("*.json")):
        try:
            out.append(json.loads(p.read_text(encoding="utf-8")))
        except (json.JSONDecodeError, OSError):
            continue
    return out
