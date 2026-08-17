---
name: broadlink-remote
description: Local Broadlink RM Max IR/RF blaster — status, list learned codes, gated send/learn.
metadata:
  openclaw:
    requires:
      env:
        - BROADLINK_ENABLED
---

# Broadlink remote (RM Max)

Use **`scripts/broadlink-device.sh`** for all Broadlink operations. Local LAN UDP only — no Broadlink cloud credentials.

## Device (this household)

| Field | Value |
|-------|--------|
| Host | `10.0.0.174` (`BL-b1-10-2a`) |
| Type | `0xaf8b` (RM Max) |
| Framing | `rmpro` (not rm4pro) |

## Safe anytime

```bash
broadlink-device.sh status
broadlink-device.sh discover
broadlink-device.sh auth
broadlink-device.sh list
broadlink-device.sh help
```

## Learn / send (gated)

Requires `BROADLINK_ENABLED=1`. Send also needs `BROADLINK_ACTUATION_ENABLED=1` after unlock SOP.

```bash
broadlink-device.sh learn --name living_tv_power --safety-class high
broadlink-device.sh send living_tv_power
```

RF is gated by `BROADLINK_RF_ENABLED=0` by default.

## Talk fast-path

`@openclaw broadlink status|list|send <name> confirm|help` via **`broadlink-talk-fast-path.sh`** on Talk shim **:8788** (also document relay **:8789**). Talk send requires trailing `confirm` when `BROADLINK_REQUIRE_TALK_CONFIRM=1`.

Never accept raw hex/base64 from Talk — named codes only.

## Unlock first

If `auth` fails, follow `docs/UNLOCK-SOP.md` (Magic Home Lock off / 3rd-party, or reset + local Wi‑Fi).
