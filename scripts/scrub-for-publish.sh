#!/usr/bin/env bash
# Fail publish if private tokens leak into the repo tree.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
FAIL=0
# Patterns live in this script only; exclude self from the scan.
BLOCKLIST='9x4f25n3|jf7zijqp|Phoebe|SUBARU_PASSWORD|sk-or-v1|OPENROUTER'
if rg -n "$BLOCKLIST" \
  --glob '!.git/**' --glob '!venv/**' --glob '!.pytest_cache/**' \
  --glob '!scripts/scrub-for-publish.sh' \
  README.md docs skills config scripts tests .env.example Makefile 2>/dev/null; then
  echo "Gate BL-SCRUB: FAIL — blocklist hit" >&2
  FAIL=1
else
  echo "Gate BL-SCRUB: PASS — no private tokens in publishable tree"
fi
exit "$FAIL"
