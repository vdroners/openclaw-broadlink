#!/usr/bin/env bash
# Execute Talk fast-path Broadlink commands.
# Usage: broadlink-dispatch-exec.sh [--dry-run] "message"
set -euo pipefail

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

DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1 && shift
MSG="${1:-}"
[[ -z "$MSG" ]] && { echo "usage: $0 [--dry-run] \"@openclaw broadlink ...\"" >&2; exit 2; }

if ! parsed="$(bash "${SCRIPT_DIR}/broadlink-dispatch.sh" "$MSG" 2>/dev/null)"; then
  exit 1
fi

action="$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['action'])" "$parsed")"
args_json="$(python3 -c "import json,sys; print(json.dumps(json.loads(sys.argv[1]).get('args',[])))" "$parsed")"

if [[ "$action" == "send" ]]; then
  if [[ "${BROADLINK_ENABLED:-0}" != "1" || "${BROADLINK_ACTUATION_ENABLED:-0}" != "1" ]]; then
    python3 - <<'PY'
import json
print(json.dumps({
  "ok": False,
  "error_code": "actuation_disabled",
  "errors": ["Broadlink send is disabled. Enable BROADLINK_ENABLED + BROADLINK_ACTUATION_ENABLED after unlock."],
}))
PY
    exit 0
  fi
  if [[ "${BROADLINK_TALK_FASTPATH:-0}" == "1" && "${BROADLINK_REQUIRE_TALK_CONFIRM:-1}" == "1" ]]; then
    if ! printf '%s' "$MSG" | grep -qiE '(^|[[:space:]])confirm($|[[:space:]])'; then
      python3 - <<'PY'
import json
print(json.dumps({
  "ok": False,
  "error_code": "actuation_confirm_required",
  "errors": ["Talk send requires 'confirm' (e.g. @openclaw broadlink send living_tv_power confirm)."],
}))
PY
      exit 0
    fi
  fi
fi

mapfile -t cli_args < <(python3 - "$action" "$args_json" <<'PY'
import json, sys
action = sys.argv[1]
args = json.loads(sys.argv[2])
out = [action]
if action == "send" and args:
    out.append(args[0])
elif action == "learn" and args:
    out.extend(["--name", args[0]])
    if len(args) > 1:
        out.extend(args[1:])
print("\n".join(out))
PY
)

if [[ "$DRY" -eq 1 ]]; then
  echo "BROADLINK_DISPATCH_DRY action=${action} cmd=broadlink-device.sh ${cli_args[*]}"
  exit 0
fi

bash "${SCRIPT_DIR}/broadlink-device.sh" "${cli_args[@]}"
