#!/usr/bin/env bash
# Offline smoke: schema + framing unit + dry-run send gate.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FAIL=0
pass() { echo "Gate $1: PASS — $2"; }
fail() { echo "Gate $1: FAIL — $2" >&2; FAIL=1; }

# BL-SCHEMA
if python3 - "$ROOT" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
cfg = json.loads((root / "config/broadlink-devices.example.json").read_text())
assert cfg["schema_version"] == 1
assert cfg["devices"][0]["type"] == "0xaf8b"
assert cfg["devices"][0]["host"] == "10.0.0.174"
PY
then pass BL-SCHEMA "example devices JSON ok"; else fail BL-SCHEMA "example invalid"; fi

# BL-FRAMING-AF8B
if python3 - "$ROOT/scripts/lib" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from broadlink_core import RM_MAX_TYPE
assert RM_MAX_TYPE == 0xAF8B
PY
then pass BL-FRAMING-AF8B "RM Max type constant"; else fail BL-FRAMING-AF8B "constant wrong"; fi

# BL-SEND-GATED (dry)
out="$(BROADLINK_ENABLED=1 BROADLINK_ACTUATION_ENABLED=0 bash "${SCRIPT_DIR}/broadlink-device.sh" --dry-run send demo 2>/dev/null || true)"
if echo "$out" | grep -q '"dry_run": true\|"ok": true'; then
  pass BL-SEND-GATED "dry-run send path works"
else
  # without a code file, non-dry would fail; dry should still emit
  out2="$(BROADLINK_DRY_RUN=1 BROADLINK_ENABLED=1 bash "${SCRIPT_DIR}/broadlink-device.sh" send demo 2>/dev/null || true)"
  if echo "$out2" | grep -q dry_run; then
    pass BL-SEND-GATED "BROADLINK_DRY_RUN send ok"
  else
    fail BL-SEND-GATED "out=$out out2=$out2"
  fi
fi

# BL-DISPATCH
if OPENCLAW_AGENT_MENTION=@openclaw bash "${SCRIPT_DIR}/broadlink-dispatch.sh" "@openclaw broadlink status" >/tmp/bl-disp.json 2>/dev/null; then
  act="$(python3 -c "import json; print(json.load(open('/tmp/bl-disp.json'))['action'])")"
  [[ "$act" == "status" ]] && pass BL-DISPATCH "parse status" || fail BL-DISPATCH "got $act"
else
  fail BL-DISPATCH "parse failed"
fi

# BL-TALK-CONFIRM
out_no="$(BROADLINK_TALK_FASTPATH=1 BROADLINK_REQUIRE_TALK_CONFIRM=1 BROADLINK_ENABLED=1 BROADLINK_ACTUATION_ENABLED=1 \
  OPENCLAW_AGENT_MENTION=@openclaw bash "${SCRIPT_DIR}/broadlink-dispatch-exec.sh" "@openclaw broadlink send demo" 2>/dev/null || true)"
if echo "$out_no" | grep -q actuation_confirm_required; then
  pass BL-TALK-CONFIRM "confirm required"
else
  fail BL-TALK-CONFIRM "out=$out_no"
fi

# BL-LEARN-DRY
out_l="$(BROADLINK_ENABLED=1 bash "${SCRIPT_DIR}/broadlink-device.sh" --dry-run learn --name demo_power --safety-class high 2>/dev/null || true)"
if echo "$out_l" | grep -q dry_run; then
  pass BL-LEARN-DRY "learn dry-run"
else
  fail BL-LEARN-DRY "out=$out_l"
fi

echo "BROADLINK_SMOKE_OK hard_fail=$FAIL"
exit "$FAIL"
