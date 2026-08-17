"""Talk-facing match helpers for Broadlink fast-path."""

from __future__ import annotations

import json
import re

from broadlink_dispatch_parse import is_broadlink_command  # noqa: F401


def normalize_talk_text(text: str) -> str:
    return re.sub(r"\s+", " ", (text or "").strip())


def extract_user_message(text: str) -> str:
    raw = text or ""
    # Unwrap common Talk JSON envelopes
    try:
        data = json.loads(raw)
        if isinstance(data, dict):
            for key in ("message", "text", "content"):
                if isinstance(data.get(key), str) and data[key].strip():
                    return data[key].strip()
    except (json.JSONDecodeError, TypeError):
        pass
    return normalize_talk_text(raw)


def is_tool_json_payload(text: str) -> bool:
    t = (text or "").strip()
    if not (t.startswith("{") and t.endswith("}")):
        return False
    try:
        data = json.loads(t)
    except json.JSONDecodeError:
        return False
    if not isinstance(data, dict):
        return False
    return any(k in data for k in ("tool_call", "toolCall", "name", "arguments", "function"))
