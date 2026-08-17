#!/usr/bin/env bash
# Optional helper: import a SmartIR Broadlink Base64 JSON fragment as named codes.
# Phase-3 / optional — does not fetch the network by default.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/load-broadlink-env.sh"

cat <<'EOF'
SmartIR import workflow (manual):

1. Browse community packs: https://github.com/smartHomeHub/SmartIR
   Browser helper: https://github.com/ldelvalleh/SMARTIR-HAIR-CONVERSOR
2. Guided learn→JSON: https://github.com/ericellb/broadlink-cli-smartir
3. For each Broadlink Base64 command, write a code file:

   BROADLINK_ENABLED=1 bash broadlink-device.sh --dry-run learn --name living_tv_power

   Or save directly under $BROADLINK_CODES_DIR/<name>.json with:
     media=ir, encoding=broadlink_base64, payload=<SmartIR string>, safety_class=low|high

4. Test send only after unlock + BROADLINK_ACTUATION_ENABLED=1.

This script is documentation-only in v0 (no automatic download).
EOF
echo "BROADLINK_SMARTIR_IMPORT stub ok"
