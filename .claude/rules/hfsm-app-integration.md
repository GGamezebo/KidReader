---
description: App-level HFSM integration
paths:
  - "src/game/main.gd"
  - "src/game/hfsm/**/*"
  - "src/game/scenes/app_root/**/*"
---

# App HFSM integration

- Entry: `main.tscn` → `main.gd` boots HFSM
- Config: `src/game/hfsm/app_hfsm.json`
- Paths: `HfsmScenePaths`
- Root mounts `app_root`; phases: `menu` / `game`
- Bridge: `RootEvents.ev_*` → `hfsm.add_event` on **app_root**
- In-level `GameManager` FSM stays separate from HFSM
