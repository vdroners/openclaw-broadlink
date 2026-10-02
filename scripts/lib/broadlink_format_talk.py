#!/usr/bin/env python3
"""Format Broadlink JSON (stdin) for Talk — short text."""
from __future__ import annotations

import json
import sys


def main() -> int:
    try:
        p = json.load(sys.stdin)
    except Exception:
        print("Broadlink: bad response")
        return 0
    if not p.get("ok"):
        err = (p.get("errors") or [p.get("error_code") or "failed"])[0]
        print(f"Broadlink: {err}")
        hint = p.get("hint")
        if hint:
            print(hint)
        return 0
    cmd = p.get("command")
    if cmd == "list":
        codes = p.get("codes") or []
        if not codes:
            print("Broadlink: no learned codes yet. Use CLI learn after unlock.")
        else:
            names = ", ".join(c.get("name") for c in codes[:20])
            print(f"Broadlink codes ({p.get('count', len(codes))}): {names}")
    elif cmd == "status":
        d = p.get("device") or {}
        locked = p.get("is_locked")
        lock_s = "locked" if locked else ("unlocked" if locked is False else "lock=?")
        auth = "auth ok" if p.get("auth") else "auth FAILED"
        print(
            f"Broadlink {d.get('id') or 'rm-max'} @ {d.get('host')} "
            f"{d.get('type')} {p.get('class')} hello={p.get('hello')} "
            f"{auth} ({lock_s})"
        )
        if p.get("hint"):
            print(p["hint"])
    elif cmd == "send":
        print(f"Broadlink: sent {p.get('name')}")
    elif cmd == "learn":
        if p.get("dry_run"):
            print(f"Broadlink: would learn {p.get('name')}")
        else:
            print(f"Broadlink: learned {p.get('name')}")
    elif cmd == "help":
        print("Broadlink: status | list | send <name> confirm | help")
    else:
        print(f"Broadlink: {cmd} ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
