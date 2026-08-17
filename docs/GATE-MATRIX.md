# Gate matrix (BL-*)

| Gate | What |
|------|------|
| BL-SCRUB | No private Alfred tokens in publishable tree |
| BL-SCHEMA | Example devices JSON valid |
| BL-FRAMING-AF8B | `0xAF8B` constant / rmpro intent |
| BL-CODE-SCHEMA | Named code store validation |
| BL-DISPATCH | Talk phrase parse |
| BL-TALK-CONFIRM | Talk send requires `confirm` |
| BL-LEARN-DRY | Learn dry-run |
| BL-SEND-GATED | Send blocked without actuation / dry-run ok |
| BL-HELLO | Live unicast hello (optional live gate) |
| BL-AUTH | Live auth after unlock (optional live gate) |

Run: `make smoke` / `make feature-gates` / `make publish`.
