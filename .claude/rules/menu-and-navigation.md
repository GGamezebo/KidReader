---
description: Menu, windows, and RootEvents navigation
paths:
  - "src/game/scenes/menu/**/*"
  - "src/game/scenes/app_root/**/*"
  - "core/lib/window_stack_manager/**/*"
---

# Menu & navigation

1. Scenes (Menu/Level) — only via `RootEvents`
2. Full-screen windows — `WindowStackManager`
3. Dialogs/overlays (parental gate, pause) — NOT on the window stack

## Game start

- Payload: `{ "level_id": int }` or `{ "level_data": LevelData }`
- Return: `ev_return_to_menu`
- Next level: `ev_start_level` with next id (remounts Level)

## Avoid

- Loading `GameScene` from menu scripts directly
- Parental gate on the window stack
