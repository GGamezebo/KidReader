---
description: HFSM JSON config conventions
paths:
  - "**/*hfsm*.json"
---

# HFSM JSON config

- Exactly one root state key
- Reserved: `enter`, `leave`, `consume`, `states`, `scene`
- Prefer `ev.*` events; omit `enter` → `["sys.enter"]`
- Heavy screens: `scene`; menu windows use `WindowStackManager`, not HFSM
