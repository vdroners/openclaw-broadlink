#!/usr/bin/env bash
# Load Broadlink env from ~/.openclaw/.env
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
ROOT="${OPENCLAW_BROADLINK_ROOT:-}"

_preserve_enabled="${BROADLINK_ENABLED-__unset__}"
_preserve_actuation="${BROADLINK_ACTUATION_ENABLED-__unset__}"

if [[ -z "$ROOT" && -d "${SCRIPT_DIR}/../config" ]]; then
  ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

ENV_FILE="${OPENCLAW_DIR}/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

if [[ -n "$ROOT" && -f "${ROOT}/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "${ROOT}/.env"
  set +a
fi

if [[ "$_preserve_enabled" != "__unset__" ]]; then
  export BROADLINK_ENABLED="$_preserve_enabled"
fi
if [[ "$_preserve_actuation" != "__unset__" ]]; then
  export BROADLINK_ACTUATION_ENABLED="$_preserve_actuation"
fi

export OPENCLAW_DIR
export BROADLINK_HOST="${BROADLINK_HOST:-10.0.0.174}"
export BROADLINK_MAC="${BROADLINK_MAC:-34:8e:89:b1:10:2a}"
export BROADLINK_TYPE="${BROADLINK_TYPE:-0xaf8b}"
export BROADLINK_NICKNAME="${BROADLINK_NICKNAME:-rm-max}"
export BROADLINK_DEVICES_JSON="${BROADLINK_DEVICES_JSON:-${OPENCLAW_DIR}/config/broadlink-devices.json}"
export BROADLINK_CODES_DIR="${BROADLINK_CODES_DIR:-${OPENCLAW_DIR}/state/broadlink-codes}"
export BROADLINK_VENV="${BROADLINK_VENV:-${OPENCLAW_DIR}/venv-broadlink}"

if [[ -x "${BROADLINK_VENV}/bin/python3" ]]; then
  BROADLINK_PYTHON="${BROADLINK_VENV}/bin/python3"
else
  BROADLINK_PYTHON="${BROADLINK_PYTHON:-python3}"
fi
export BROADLINK_PYTHON
