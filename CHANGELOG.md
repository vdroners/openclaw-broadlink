# Changelog

## [Unreleased]

### Added

- Initial `openclaw-broadlink` sibling for Broadlink RM Max (`0xaf8b` @ 10.0.0.174).
- `rmpro` framing overlay, CLI façade, code schema, Talk dispatch + confirm, BL-* gates.
- Unlock SOP, Talk wiring docs, SmartIR import stub (Phase 3).

### Verified (lab)

- Unicast hello/discover → `RMPRO` / `FCBLE GW` / MAC `34:8e:89:b1:10:2a`.
- `auth()` still fails until Magic Home unlock (documented in `docs/UNLOCK-SOP.md` / `LEARN-PROOF.md`).
- `make publish` green; Talk shim health lists `broadlink`.
