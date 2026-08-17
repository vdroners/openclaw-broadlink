# Code storage schema

Live codes: `~/.openclaw/state/broadlink-codes/<name>.json`

```json
{
  "id": "living_tv_power",
  "name": "living_tv_power",
  "media": "ir",
  "encoding": "broadlink_base64",
  "payload": "JgAcAB0d…",
  "device": "rm-max",
  "safety_class": "high",
  "aliases": ["tv_power"],
  "learned_at": "2026-08-17T00:00:00+00:00",
  "notes": ""
}
```

| Field | Rules |
|-------|--------|
| `name` / `id` | slug `[a-z0-9][a-z0-9_-]{0,63}` |
| `media` | `ir` or `rf` |
| `encoding` | `broadlink_base64` (v0) |
| `safety_class` | `low` (volume) or `high` (power/HVAC/RF gate) |
| Talk | **named codes only** — no raw payloads from chat |

Devices inventory: `~/.openclaw/config/broadlink-devices.json` (see example + JSON Schema in `config/`).
