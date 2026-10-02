# Changelog

## [Unreleased]

### Added

- Initial `openclaw-broadlink` sibling for Broadlink RM Max (`0xaf8b` @ 10.0.0.174).
- `rmpro` framing overlay, CLI façade, code schema, Talk dispatch + confirm, BL-* gates.
- Unlock SOP, Talk wiring docs, SmartIR import stub (Phase 3).
- `docs/LOCKED-CAPABILITIES.md`: what works and what is blocked while the RM Max is LAN-locked.

### Changed

- `status` / `auth` JSON now report `is_locked`, `manufacturer`, `model_runtime` and an unlock `hint`.
- Talk reply formatter moved from an inline heredoc to `scripts/lib/broadlink_format_talk.py`; status line shows lock state.
- Unlock SOP rewritten for RM Max (no Lock toggle in the official app): Path A Magic Home 3rd-party, Path B reset + Wi‑Fi only.

### Verified (lab)

- Unicast hello/discover → `RMPRO` / `FCBLE GW` / MAC `34:8e:89:b1:10:2a`.
- `auth()` still fails until LAN unlock (documented in `docs/UNLOCK-SOP.md` / `LEARN-PROOF.md`). Re-probed 2026-09-05: `is_locked=True`, FW v62336, no Lock toggle in the official app.
- `make publish` green; Talk shim health lists `broadlink`.
