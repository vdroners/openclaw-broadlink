# Security

- No Broadlink cloud credentials in v0.
- Learned IR/RF codes are not secrets but stay under `~/.openclaw/state/` (gitignored live tree).
- Actuation and RF remain opt-in.
- Talk path rejects raw hex/base64.
- Optional HTTP bridge, if added later, must bind **loopback only** on a free port (e.g. 18792), never 8790.
