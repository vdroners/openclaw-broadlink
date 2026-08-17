#!/usr/bin/env bash
# Run Broadlink Talk dispatch + formatter + talk-post (no LLM).
set -euo pipefail

MSG="${1:-}"
ROOM="${2:-}"
if [[ -z "$MSG" || -z "$ROOM" ]]; then
  echo "usage: $0 \"<message>\" <room_token>" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/load-broadlink-env.sh"
if [[ -f "${SCRIPT_DIR}/load-agent-env.sh" ]]; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/load-agent-env.sh" 2>/dev/null || true
fi

export BROADLINK_TALK_FASTPATH=1

dispatch="${SCRIPT_DIR}/broadlink-dispatch-exec.sh"
formatter="${SCRIPT_DIR}/broadlink-format-talk-reply.sh"
talk_post="${HOME}/.openclaw/scripts/talk-post.sh"
[[ -x "$talk_post" ]] || talk_post="${HOME}/openclaw-skylight/scripts/talk-post.sh"
if [[ ! -x "$talk_post" ]]; then
  echo "broadlink-talk-fast-path: talk-post.sh not found" >&2
  exit 1
fi

clean_msg="$("$BROADLINK_PYTHON" - "$MSG" "$SCRIPT_DIR" <<'PY'
import sys
from pathlib import Path
sys.path.insert(0, str(Path(sys.argv[2]) / "lib"))
from broadlink_talk_match import extract_user_message, is_tool_json_payload
raw = sys.argv[1]
if is_tool_json_payload(raw):
    sys.exit(2)
print(extract_user_message(raw))
PY
)" || {
  echo "broadlink-talk-fast-path: ignored tool JSON" >&2
  exit 0
}

result="$(bash "$dispatch" "$clean_msg" 2>/dev/null)" || result=""
if [[ -z "$result" ]]; then
  summary="Broadlink: could not parse that. Try: @openclaw broadlink status"
elif ! printf '%s' "$result" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
  summary="Broadlink: command failed."
else
  summary="$(printf '%s' "$result" | bash "$formatter" 2>/dev/null || true)"
fi
[[ -z "$summary" ]] && summary="Broadlink: command failed. Try: @openclaw broadlink status"
summary="$(printf '%s' "$summary" | grep -v '^BROADLINK_' | head -c 500 | sed '/./,$!d')"
bash "$talk_post" "$summary" "$ROOM"
echo "broadlink-talk-fast-path: ok room=$ROOM chars=${#summary}"
