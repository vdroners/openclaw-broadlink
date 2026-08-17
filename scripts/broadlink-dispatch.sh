#!/usr/bin/env bash
# Parse Talk: [@]agent broadlink <subcommand>
set -euo pipefail

MSG="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_SAVED_MENTION="${OPENCLAW_AGENT_MENTION:-}"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/load-broadlink-env.sh"
if [[ -f "${SCRIPT_DIR}/load-agent-env.sh" ]]; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/load-agent-env.sh" 2>/dev/null || true
fi
if [[ -n "$_SAVED_MENTION" ]]; then
  export OPENCLAW_AGENT_MENTION="$_SAVED_MENTION"
fi
MENTION="${OPENCLAW_AGENT_MENTION:-@openclaw}"
AGENT_NAME="${MENTION#@}"

[[ -z "$MSG" ]] && exit 1
exec "$BROADLINK_PYTHON" "${SCRIPT_DIR}/lib/broadlink_dispatch_parse.py" "$MSG" "$AGENT_NAME"
