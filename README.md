# openclaw-broadlink

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-2026.4+-green.svg)](https://github.com/openclaw/openclaw)

**OpenClaw skill + shell automation for Broadlink RM Max** — local IR/RF learn & send via a patched [`python-broadlink`](https://github.com/mjg59/python-broadlink) stack.

> **Local LAN only.** Actuation is off by default (`BROADLINK_ACTUATION_ENABLED=0`) until unlock SOP + learn proof pass.

Sibling of [openclaw-subaru](https://github.com/vdroners/openclaw-subaru) and [openclaw-skylight](https://github.com/vdroners/openclaw-skylight).

---

## Household device (lab)

| Field | Value |
|-------|--------|
| Hostname | `BL-b1-10-2a` |
| IP | `10.0.0.174` |
| MAC | `34:8e:89:b1:10:2a` |
| Type | `0xaf8b` (RM Max) |
| Discovery name | `FCBLE GW` |

RM Max needs **`rmpro` framing** (see issue [#829](https://github.com/mjg59/python-broadlink/issues/829) / PR [#838](https://github.com/mjg59/python-broadlink/pull/838)). Overlay: `scripts/lib/broadlink_core.py`.

---

## Quick start

```bash
cd /media/4TB/openclaw-broadlink
make venv
# Merge .env.example keys into ~/.openclaw/.env
bash scripts/install-to-openclaw.sh --force
make smoke
BROADLINK_ENABLED=1 bash scripts/broadlink-device.sh discover
BROADLINK_ENABLED=1 bash scripts/broadlink-device.sh auth   # after unlock
```

Docs: [BROADLINK-RM-MAX.md](docs/BROADLINK-RM-MAX.md), [UNLOCK-SOP.md](docs/UNLOCK-SOP.md), [LOCKED-CAPABILITIES.md](docs/LOCKED-CAPABILITIES.md), [LEARN-PROOF.md](docs/LEARN-PROOF.md), [TALK-WIRING.md](docs/TALK-WIRING.md).

---

## Talk (no LLM)

After shim/relay wiring:

`@openclaw broadlink status|list|send <name> confirm|help`

---

## Safety

- `BROADLINK_ENABLED=0` / `BROADLINK_ACTUATION_ENABLED=0` defaults
- Talk send requires `confirm`
- RF gated (`BROADLINK_RF_ENABLED=0`)
- Named codes only — no raw payloads from Talk
- Never claim port **8790** (forge)

---

## License

MIT — see [LICENSE](LICENSE).
