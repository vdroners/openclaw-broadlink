# Talk wiring — Broadlink

## Ports

| Port | Role | Broadlink |
|------|------|-----------|
| 8788 | Talk webhook **shim** (openclaw-skylight) | **Primary** fast-path |
| 8789 | `nc-webhook-relay` | Secondary — patch similarly |
| 8787 | OpenClaw plugin webhook | Upstream after fast-paths |
| 8790 | forge-webhook-relay | **Do not use** |

## Shim (8788)

`openclaw-skylight/scripts/talk-webhook-shim.py` (symlinked into `~/.openclaw/scripts/`) must call `is_broadlink_command` and run `broadlink-talk-fast-path.sh`.

Lib path: ensure `~/.openclaw/scripts/lib` includes `broadlink_talk_match.py` (install-to-openclaw symlinks).

## Relay (8789)

`~/.openclaw/nc-webhook-relay.py` should mirror subaru/roomba: detect `@alfred broadlink …` and exec `broadlink-talk-fast-path.sh`.

## Verbs

- `@alfred broadlink status`
- `@alfred broadlink list`
- `@alfred broadlink send <name> confirm`
- `@alfred broadlink help`

Send without `confirm` returns `actuation_confirm_required` when `BROADLINK_REQUIRE_TALK_CONFIRM=1`.
