# Unlock SOP — Broadlink RM Max local auth

Local `auth()` is required before learn/send. Phone-app control can work while third-party LAN auth is locked.

## Device fingerprint (this unit)

From Broadlink app “Device own info” (2026-09-05):

| Field | Value |
|-------|--------|
| IP | `10.0.0.174@80` |
| MAC | `34:8e:89:b1:10:2a` |
| DID | `…348e89b1102a` |
| PID | `…8baf0000` (`0xAF8B` little-endian — RM Max) |
| Firmware | **v62336** |
| SDK | **2.18.10** |
| Plug-in | 1.6.8 |
| Data / IoT Cloud | Other regions |

Alfred probe: unicast hello OK (`RMPRO` / `FCBLE GW`); `device.is_locked == True` after failed `auth()`; broadcast discover empty.

## Why you may not see “Lock device”

On **RM Max**, the official Broadlink app often **omits** the Lock / Property toggle entirely (reported on [python-broadlink#829](https://github.com/mjg59/python-broadlink/issues/829)). Missing UI ≠ unlocked. Our probe still sees `is_locked=True`.

## Path A — Magic Home “3rd-party” (try before reset)

1. Install / open **Magic Home** (legacy Broadlink client), same Wi‑Fi as the RM Max.
2. Add or open the RM Max if it appears.
3. Look for **Connect to a 3rd-party** / local **server** or **client** and enable third-party / local control.
4. Force-quit the app.
5. From Alfred:

```bash
BROADLINK_ENABLED=1 bash /media/4TB/openclaw-broadlink/scripts/broadlink-device.sh auth
```

Expected: `"ok": true, "command": "auth"`.

If Magic Home cannot add the device or has no 3rd-party control, go to Path B.

## Path B — Wi‑Fi only / abort cloud bind (recommended when Lock UI is missing)

1. In the Broadlink app, **delete / remove** the RM Max from the account.
2. **Factory reset:** hold reset ~6s until the LED blinks fast.
3. Re-add and complete **Wi‑Fi join only**.
4. As soon as it is on the LAN (`10.0.0.174` or a new DHCP lease), **force-quit the Broadlink app** before finishing cloud pairing / room / lock prompts.
5. Prefer a **static DHCP reservation** for `34:8e:89:b1:10:2a` → `10.0.0.174`.
6. Retry `auth` (command above).

Trade-off: phone cloud features may stop; local Alfred control is the goal.

## Path C — still failing

- Same subnet as `10.0.0.84` (no AP isolation).
- Confirm discover: `BROADLINK_ENABLED=1 bash …/broadlink-device.sh discover`
- Framing is already `RMPRO` for `0xaf8b` (correct per PR #838; wrong class causes *fake* lock — we are past that).

## Auth probe result (this install)

| When (UTC) | Hello | Auth | Class | Notes |
|------------|-------|------|-------|-------|
| 2026-08-17 | **ok** | **FAIL** | `RMPRO` | First probe |
| 2026-09-05 | **ok**; `is_locked=True`; FW v62336 / SDK 2.18.10 | **FAIL** | `RMPRO` | Operator: no Lock UI in Broadlink app; Path A Magic Home 3rd-party or Path B |

**Learn/send blocked** until auth succeeds. Do not set `BROADLINK_ACTUATION_ENABLED=1` until one IR learn+send works.
