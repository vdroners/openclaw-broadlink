# Broadlink RM Max — device notes

## Fingerprint (lab LAN)

| Field | Value |
|-------|--------|
| Hostname | `BL-b1-10-2a` |
| IP | `10.0.0.174` |
| MAC | `34:8e:89:b1:10:2a` |
| Device type | `0xaf8b` |
| Discovery name | `FCBLE GW` |
| Unicast hello | Works from Alfred host |
| Broadcast discover | Often empty (treat as cloud-lock signal) |
| Auth (2026-08-17) | **FAIL** until Magic Home unlock — see [UNLOCK-SOP.md](UNLOCK-SOP.md) |
| Framing class | Discover returns `RMPRO` (overlay OK) |

## Protocol

- Control is **UDP AES** on port 80 (not HTTP).
- Map `0xAF8B` to **`rmpro`** framing (`<I`), not `rm4pro` (`<HI`).
- Upstream tracking: [python-broadlink#829](https://github.com/mjg59/python-broadlink/issues/829), [PR #838](https://github.com/mjg59/python-broadlink/pull/838).
- Overlay lives in `scripts/lib/broadlink_core.py`.

## Useful upstream repos

| Repo | Use |
|------|-----|
| mjg59/python-broadlink | Local library |
| Leproide/Broadlink-Gate-Bot | Learn/send JSON + unlock SOP patterns |
| smartHomeHub/SmartIR | Community Base64 packs (Phase 3) |
| ericellb/broadlink-cli-smartir | Guided multi-key learn |

Do **not** stand up Home Assistant solely for this blaster. Do **not** bind any bridge to port **8790** (forge owns it); prefer `127.0.0.1:18792` if needed later.
