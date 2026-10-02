# Locked-mode capability matrix (RM Max @ 10.0.0.174)

Explored **2026-09-05** with device still cloud-locked (`is_locked=True`, firmware **v62336**, SDK **2.18.10**). Path B reset **not** done yet.

## LAN protocol

| Op | Result while locked |
|----|---------------------|
| Unicast UDP hello | **Works** — name `FCBLE GW`, type `0xaf8b`, class `RMPRO` |
| Broadcast discover | Empty |
| TCP 80/443/… | Closed (UDP AES only) |
| `ping` / `get_type` / device `hello()` | **Works** (no auth key) |
| `auth()` | **FAIL** — Authentication failed; `is_locked` stays True; no AES session key |
| `set_lock(False)` | **FAIL** — AuthorizationError (needs auth key) |
| `get_fwversion` / sensors / temp | **FAIL** — Control key expired |
| `enter_learning` / `check_data` / `send_data` | **FAIL** — Control key expired |
| RF sweep / learn | **FAIL** — same |
| Cloud / Magic Home REST from Alfred | **Not used** (v0 is local-only) |

**Bottom line:** while locked we can **see** the blaster on the LAN and drive Alfred plumbing; we **cannot** learn, send, rename, unlock, or read firmware over the local protocol.

## Alfred / OpenClaw stack (works now)

| Surface | Locked behavior |
|---------|-----------------|
| `broadlink-device.sh discover` | OK |
| `… status` | hello OK + `auth_failed` + `is_locked` |
| `… auth` | FAIL + unlock hint |
| `… list` | OK (empty code store) |
| `… help` | OK |
| `… --dry-run learn/send` | OK (no IR) |
| `… learn` / `send` (live) | Blocked until auth (+ actuation for send) |
| Talk `@alfred broadlink status\|list\|help` | Fast-path works |
| Talk `send …` | Blocked by confirm + actuation flags |
| Talk `send … confirm` | Still blocked until unlock + `BROADLINK_ACTUATION_ENABLED=1` |
| Gates `make publish` | Green offline |
| Skill `broadlink-remote` | Installed, `enabled:false` in openclaw.json (env gates drive CLI) |

## Operator-only (phone) — no reset yet

| Action | Purpose |
|--------|---------|
| Broadlink app remote IR | Still works via cloud; does not unlock LAN |
| Magic Home **Connect to a 3rd-party** | Optional Path A without reset (try anytime) |
| Path B factory reset + Wi‑Fi abort | Next step when you say go |

## After unlock (Path B) — expected new capabilities

1. `auth` → ok, `is_locked=False`
2. Learn one IR → save under `~/.openclaw/state/broadlink-codes/`
3. `BROADLINK_ACTUATION_ENABLED=1` → send + Talk `send <name> confirm`
4. Optional RF (still gated `BROADLINK_RF_ENABLED=0`)
5. Optional SmartIR pack import (Phase 3)

## Commands to re-check after any phone change

```bash
BROADLINK_ENABLED=1 bash /media/4TB/openclaw-broadlink/scripts/broadlink-device.sh status
BROADLINK_ENABLED=1 bash /media/4TB/openclaw-broadlink/scripts/broadlink-device.sh auth
```
