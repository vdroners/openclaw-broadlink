#!/usr/bin/env bash
# Format Broadlink JSON for Talk (short text). JSON on stdin.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "${SCRIPT_DIR}/lib/broadlink_format_talk.py"
