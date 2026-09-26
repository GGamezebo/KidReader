---
description: Levels and progress persistence
paths:
  - "src/common/**/*"
  - "src/levels/**/*"
  - "src/game/account/**/*"
  - "src/game/scenes/app_root/**/*"
---

# Levels & progress

- Canonical: `src/levels/level_N.tres` (`LevelData`)
- Catalog: `src/common/levels_catalog.gd`
- Progress: `PData` — stars per level, highest unlocked
- Disk: `SaveManager` → `user://save/progress.json` via `ResourceUtils`
- Mutations: `ProgressController` only
- Writes: only `SaveManager` on `RootEvents.ev_save_progress` (debounced; suppressed during level; flush on level end / app close)

## Must

- Keep level ids stable
- Bump `PData.CURRENT_SAVE_VERSION` + migrate when schema changes
