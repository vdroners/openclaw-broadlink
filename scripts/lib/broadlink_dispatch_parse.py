"""Parse Talk / CLI dispatch for Broadlink fast-path."""

from __future__ import annotations

import re
from typing import Any

KNOWN = frozenset(
    {
        "status",
        "list",
        "help",
        "discover",
        "auth",
        "send",
        "learn",
        "codes",
    }
)


def parse_dispatch(message: str, agent_name: str = "openclaw") -> dict[str, Any] | None:
    """Return {action, args} or None if not a broadlink command."""
    text = (message or "").strip()
    # Strip mention chips
    text = re.sub(r"\{mention-user\d+\}", " ", text, flags=re.I)
    text = re.sub(rf"(?i)@?{re.escape(agent_name)}\b", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    m = re.match(r"(?i)^broadlink(?:\s+|$)(.*)$", text)
    if not m:
        # also accept bare "bl …"
        m = re.match(r"(?i)^bl(?:\s+|$)(.*)$", text)
        if not m:
            return None
    rest = (m.group(1) or "").strip()
    if not rest:
        return {"action": "status", "args": []}
    parts = rest.split()
    # trailing confirm is for Talk safety — strip from parse, caller still sees raw MSG
    if parts and parts[-1].lower() == "confirm":
        parts = parts[:-1]
    if not parts:
        return {"action": "status", "args": []}
    action = parts[0].lower()
    if action == "codes":
        action = "list"
    if action not in KNOWN:
        return {"action": "help", "args": []}
    return {"action": action, "args": parts[1:]}


def is_broadlink_command(text: str, agent_name: str = "openclaw") -> bool:
    norm = re.sub(r"\{mention-user\d+\}", " ", text or "", flags=re.I)
    norm = re.sub(r"\s+", " ", norm).strip()
    agent = re.escape(agent_name.lstrip("@"))
    return bool(
        re.search(rf"(?i)(?:^|\s)@?{agent}\s+broadlink\b", norm)
        or re.search(r"(?i)(?:^|\s)broadlink\s+(status|list|help|send|learn|auth|discover)\b", norm)
        or re.search(rf"(?i)(?:^|\s)@?{agent}\s+bl\b", norm)
    )


if __name__ == "__main__":
    import json
    import sys

    msg = sys.argv[1] if len(sys.argv) > 1 else ""
    agent = sys.argv[2] if len(sys.argv) > 2 else "openclaw"
    out = parse_dispatch(msg, agent)
    if out is None:
        sys.exit(1)
    print(json.dumps(out))
