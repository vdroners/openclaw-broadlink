#!/usr/bin/env bash
# Format Broadlink JSON for Talk (short text).
set -euo pipefail
python3 - <<'PY'
import json, sys
try:
    p = json.load(sys.stdin)
except Exception:
    print("Broadlink: bad response")
    sys.exit(0)
if not p.get("ok"):
    err = (p.get("errors") or [p.get("error_code") or "failed"])[0]
    print(f"Broadlink: {err}")
    hint = p.get("hint")
    if hint:
        print(hint)
    sys.exit(0)
cmd = p.get("command")
if cmd == "list":
    codes = p.get("codes") or []
    if not codes:
        print("Broadlink: no learned codes yet. Use CLI learn.")
    else:
        names = ", ".join(c.get("name") for c in codes[:20])
        print(f"Broadlink codes ({p.get('count', len(codes))}): {names}")
elif cmd == "status":
    d = p.get("device") or {}
    auth = "auth ok" if p.get("auth") else "auth FAILED — unlock required"
    print(
        f"Broadlink {d.get('id') or 'rm-max'} @ {d.get('host')} "
        f"type={d.get('type')} class={p.get('class')} hello={p.get('hello')} ({auth})"
    )
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
PY
