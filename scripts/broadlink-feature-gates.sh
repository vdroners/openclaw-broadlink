#!/usr/bin/env bash
# Offline feature gates (CI-safe).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIB="${ROOT}/scripts/lib"
FAIL=0
pass() { echo "Gate $1: PASS — $2"; }
fail() { echo "Gate $1: FAIL — $2" >&2; FAIL=1; }

bash "${SCRIPT_DIR}/broadlink-smoke.sh" || FAIL=1

# BL-CODE-SCHEMA unit
if python3 - "$LIB" <<'PY'
import sys, tempfile
from pathlib import Path
sys.path.insert(0, sys.argv[1])
from broadlink_codes import save_code, load_code, list_codes, validate_code_record
bad = validate_code_record({"name": "Bad Name", "media": "ir", "payload": "x"})
assert bad
tmp = Path(tempfile.mkdtemp())
save_code({"name": "tv_power", "media": "ir", "payload": "AAAA", "safety_class": "high"}, root=tmp)
assert load_code("tv_power", root=tmp)["safety_class"] == "high"
assert len(list_codes(root=tmp)) == 1
PY
then pass BL-CODE-SCHEMA "code store validates"; else fail BL-CODE-SCHEMA "code store broken"; fi

# BL-PARSE-ALIASES
if python3 - "$LIB" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from broadlink_dispatch_parse import parse_dispatch, is_broadlink_command
assert is_broadlink_command("@openclaw broadlink status", "openclaw")
assert parse_dispatch("@openclaw broadlink send tv_power confirm", "openclaw")["action"] == "send"
assert parse_dispatch("@openclaw broadlink list", "openclaw")["action"] == "list"
PY
then pass BL-PARSE "dispatch parse"; else fail BL-PARSE "parse broken"; fi

echo "=== broadlink-feature-gates summary (hard_fail=$FAIL) ==="
exit "$FAIL"
