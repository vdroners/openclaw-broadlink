#!/usr/bin/env bash
# Optional health probe for cron.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/load-broadlink-env.sh"
if [[ "${BROADLINK_ENABLED:-0}" != "1" ]]; then
  echo "BROADLINK_HEALTH disabled"
  exit 0
fi
if bash "${SCRIPT_DIR}/broadlink-device.sh" discover >/tmp/bl-health.json 2>/dev/null; then
  echo "BROADLINK_HEALTH ok"
  exit 0
fi
echo "BROADLINK_HEALTH fail"
exit 1
