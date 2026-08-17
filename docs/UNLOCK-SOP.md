# Unlock SOP — Broadlink RM Max local auth

Local `auth()` is required before learn/send. Phone-app control can work while third-party LAN auth is locked.

## Which app?

Use the **official Broadlink** app (iOS/Android), **not** Magic Home.

Magic Home is a legacy third-party client. Newer blasters (RM4 / RM Max) often **never show** Lock / 3rd-party toggles there — that matches “I don’t see that option.”

## Path A — unlock without reset (try first)

1. Open **Broadlink** (official).
2. Tap the **RM Max** device on the home screen.
3. Tap **⋯** (top right) → **Property** / **Device information** / **Settings**.
4. Find **Lock device** (sometimes near the bottom).
5. Toggle **Lock device → Off**. Confirm if prompted.
6. Force-quit the app.
7. From Alfred:

```bash
cd /media/4TB/openclaw-broadlink
BROADLINK_ENABLED=1 bash scripts/broadlink-device.sh auth
```

Expected success: JSON with `"ok": true, "command": "auth"`.

If there is **no Lock toggle** at all on this firmware, go to Path B.

## Path B — Wi‑Fi only / abort cloud bind (common when Lock is missing)

Community SOP used for RM4 Pro / RM Max when the lock UI is absent:

1. In the Broadlink app, **delete / remove** the RM Max from the account (if present).
2. **Factory reset** the hardware: hold reset ~6s until the LED blinks fast.
3. Re-add the device and complete **Wi‑Fi join only**.
4. As soon as it is on the LAN, **force-quit the Broadlink app** before finishing cloud pairing / room assignment / “lock” prompts when possible.
5. Prefer a **static DHCP reservation** for `34:8e:89:b1:10:2a` → `10.0.0.174`.
6. Retry `auth` from Alfred (command above).

Trade-off: phone-app cloud features may stop working; local Alfred control is the goal.

## Path C — still failing

- Same subnet as `10.0.0.84` (no AP isolation / IoT VLAN blocking UDP).
- Confirm discover still works: `BROADLINK_ENABLED=1 bash scripts/broadlink-device.sh discover`
- Re-check framing is `RMPRO` (already validated for `0xaf8b`).
- Record firmware string from the app (Property → Firmware) in [BROADLINK-RM-MAX.md](BROADLINK-RM-MAX.md).

## Auth probe result (this install)

| When (UTC) | Hello | Auth | Class | Notes |
|------------|-------|------|-------|-------|
| 2026-08-17 (agent probe) | **ok** `0xaf8b` name=`FCBLE GW` | **FAIL** `[Errno -1] Authentication failed` | `RMPRO` (framing overlay OK) | Unicast hello works; local `auth()` blocked — use official Broadlink app Path A, else Path B |

**Learn/send blocked** until auth succeeds. Do not set `BROADLINK_ACTUATION_ENABLED=1` until one IR learn+send works.
