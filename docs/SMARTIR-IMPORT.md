# SmartIR import (Phase 3 / optional)

Not part of v0 runtime. After unlock + one learned code works:

1. Prefer learning household remotes with `broadlink-device.sh learn`.
2. For large AC/TV packs, browse [SmartIR](https://github.com/smartHomeHub/SmartIR) Base64 JSON and copy commands into `~/.openclaw/state/broadlink-codes/` using the code schema.
3. Helper browser: [SMARTIR-HAIR-CONVERSOR](https://github.com/ldelvalleh/SMARTIR-HAIR-CONVERSOR).
4. Guided learn: [broadlink-cli-smartir](https://github.com/ericellb/broadlink-cli-smartir).

Stub script: `scripts/broadlink-smartir-import.sh` (prints workflow only).
