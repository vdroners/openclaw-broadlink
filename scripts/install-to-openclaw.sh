#!/usr/bin/env bash
# Symlink openclaw-broadlink into ~/.openclaw (idempotent).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

mkdir -p "${OPENCLAW_DIR}/scripts/lib" "${OPENCLAW_DIR}/workspace/skills" \
  "${OPENCLAW_DIR}/config" "${OPENCLAW_DIR}/workspace/references" \
  "${OPENCLAW_DIR}/state/broadlink-codes"

link_one() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    cur=$(readlink -f "$dst" 2>/dev/null || readlink "$dst")
    [[ "$cur" == "$src" ]] && return 0
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    if [[ "$FORCE" -eq 1 ]]; then
      rm -rf "$dst"
    else
      echo "install: skip existing $dst (use --force)" >&2
      return 0
    fi
  fi
  ln -sf "$src" "$dst"
}

sync_skill() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then
    rm -f "$dst"
  elif [[ -d "$dst" && "$FORCE" -eq 0 ]]; then
    echo "install: skip existing skill dir $dst" >&2
    return 0
  fi
  rm -rf "$dst"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "${src}/" "${dst}/"
  else
    cp -a "${src}" "${dst}"
  fi
}

for f in "${ROOT}"/scripts/*.sh "${ROOT}"/scripts/*.py; do
  [[ -f "$f" ]] || continue
  base=$(basename "$f")
  case "$base" in
    install-to-openclaw.sh|scrub-for-publish.sh) continue ;;
  esac
  link_one "$f" "${OPENCLAW_DIR}/scripts/$base"
done

for f in "${ROOT}"/scripts/lib/*.py; do
  [[ -f "$f" ]] || continue
  link_one "$f" "${OPENCLAW_DIR}/scripts/lib/$(basename "$f")"
done

sync_skill "${ROOT}/skills/broadlink-remote" "${OPENCLAW_DIR}/workspace/skills/broadlink-remote"

if [[ -f "${OPENCLAW_DIR}/.env" ]]; then
  # shellcheck source=/dev/null
  source "${OPENCLAW_DIR}/.env"
  if [[ -n "${OPENCLAW_AGENT_MENTION:-}" && "${OPENCLAW_AGENT_MENTION}" != "@openclaw" ]]; then
    find "${OPENCLAW_DIR}/workspace/skills/broadlink-remote" -name 'SKILL.md' -print0 2>/dev/null \
      | while IFS= read -r -d '' f; do
          sed -i 's/@openclaw/'"${OPENCLAW_AGENT_MENTION}"'/g' "$f"
        done
  fi
fi

if [[ ! -f "${OPENCLAW_DIR}/config/broadlink-devices.json" ]]; then
  cp "${ROOT}/config/broadlink-devices.example.json" "${OPENCLAW_DIR}/config/broadlink-devices.json"
  echo "install: copied broadlink-devices.example.json → config/broadlink-devices.json"
fi

# Register skill disabled until BROADLINK_ENABLED=1 (runtime gates still apply).
OC_JSON="${OPENCLAW_DIR}/openclaw.json"
if [[ -f "$OC_JSON" ]] && command -v python3 >/dev/null 2>&1; then
  python3 - "$OC_JSON" <<'PY'
import json, sys
from pathlib import Path
p = Path(sys.argv[1])
d = json.loads(p.read_text(encoding="utf-8"))
entries = d.setdefault("skills", {}).setdefault("entries", {})
cur = entries.get("broadlink-remote")
if cur is None:
    entries["broadlink-remote"] = {"enabled": False}
    p.write_text(json.dumps(d, indent=2) + "\n", encoding="utf-8")
    print("install: openclaw.json skills.entries.broadlink-remote=enabled:false")
elif isinstance(cur, dict) and "enabled" not in cur:
    cur["enabled"] = False
    p.write_text(json.dumps(d, indent=2) + "\n", encoding="utf-8")
    print("install: set broadlink-remote.enabled=false")
else:
    print(f"install: broadlink-remote already registered ({cur})")
PY
fi

echo "install: OPENCLAW_BROADLINK_ROOT=${ROOT}"
echo "install: Tip — patch Talk shim (openclaw-skylight) for broadlink fast-path; see docs/TALK-WIRING.md"
