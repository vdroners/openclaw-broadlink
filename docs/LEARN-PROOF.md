# Learn / send live proof

## Attempted 2026-08-17 (Alfred host)

| Step | Result |
|------|--------|
| `discover` | PASS — `0xaf8b`, `RMPRO`, `FCBLE GW` @ 10.0.0.174 |
| `auth` | FAIL — `[Errno -1] Authentication failed` (cloud lock) |
| `learn` | BLOCKED — requires auth |
| `send` | BLOCKED — requires auth + `BROADLINK_ACTUATION_ENABLED=1` |

## Operator next step

1. Complete [UNLOCK-SOP.md](UNLOCK-SOP.md) on the phone.
2. Re-run:

```bash
BROADLINK_ENABLED=1 bash /media/4TB/openclaw-broadlink/scripts/broadlink-device.sh auth
BROADLINK_ENABLED=1 bash /media/4TB/openclaw-broadlink/scripts/broadlink-device.sh learn --name living_tv_power --safety-class high
# Aim a remote at the RM Max within 30s
BROADLINK_ENABLED=1 BROADLINK_ACTUATION_ENABLED=1 bash .../broadlink-device.sh send living_tv_power
```

3. Update this file with PASS rows when done.

Offline gates (`make smoke`) cover dry-run learn/send and Talk confirm without live IR.
