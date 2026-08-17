#!/usr/bin/env bash
# Bash facade for Broadlink commands.
# Usage: broadlink-device.sh [--dry-run] <command> [args...]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/load-broadlink-env.sh"

DRY=0
DEVICE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --device) DEVICE="$2"; shift 2 ;;
    *) break ;;
  esac
done

if [[ $# -lt 1 ]]; then
  echo "usage: broadlink-device.sh [--dry-run] [--device ID] <status|discover|auth|list|learn|send|help> [args...]" >&2
  exit 2
fi

CMD=( "$BROADLINK_PYTHON" "${SCRIPT_DIR}/broadlink_cli.py" )
[[ -n "$DEVICE" ]] && CMD+=( --device "$DEVICE" )
[[ "$DRY" -eq 1 ]] && CMD+=( --dry-run )

case "$1" in
  status|discover|auth|list|help)
    CMD+=( "$1" ); shift
    CMD+=( "$@" )
    ;;
  learn)
    CMD+=( learn ); shift
    CMD+=( "$@" )
    ;;
  send)
    CMD+=( send ); shift
    CMD+=( "$@" )
    ;;
  *)
    echo "unknown command: $1" >&2
    exit 2
    ;;
esac

out="$(mktemp)"
trap 'rm -f "$out"' EXIT
if ! "${CMD[@]}" >"$out" 2>/tmp/broadlink-cli.err; then
  cat "$out" || true
  echo "BROADLINK_ERR command failed" >&2
  [[ -s /tmp/broadlink-cli.err ]] && cat /tmp/broadlink-cli.err >&2 || true
  exit 1
fi
cat "$out"
if python3 - "$out" <<'PY' >&2
import json, sys
payload = json.load(open(sys.argv[1]))
print("BROADLINK_OK" if payload.get("ok") else "BROADLINK_ERR")
sys.exit(0 if payload.get("ok") else 1)
PY
then
  :
else
  exit 1
fi
