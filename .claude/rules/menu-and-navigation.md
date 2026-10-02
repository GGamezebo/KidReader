---
description: Zoo menu (map ⇄ zone), windows, and RootEvents navigation
paths:
  - "src/game/scenes/menu/**/*"
  - "src/game/scenes/app_root/**/*"
  - "core/lib/window_stack_manager/**/*"
---

# Menu & navigation (zoo)

1. Scenes (Menu/Level) — only via `RootEvents`
2. Full-screen windows — `WindowStackManager` in `menu.tscn`: `ZooMap` (default) ⇄ `ZoneView`, `Album` (📖 in TopRight); back = `ButtonWindowBack`
3. Dialogs/overlays (parental gate, `ParentCorner`, `ArrivalOverlay`) — NOT on the window stack

## Screens (`src/game/scenes/menu/`)

- `menu.gd` — host: shares catalog/pdata, rebuilds on `pdata.changed`, `initialize({"zone_id"})` reopens that zone
- `zoo_map/` — `ZooMap` builds region bands, road (Curve2D → Line2D) and `ZoneIsland`s procedurally from `LevelsCatalog`
- `zone_view/` — `ZoneView` row of `Enclosure`s (+ static festival tent); fence drawn by `EnclosureFence` per `RegionData.enclosure_style`
- `ArrivalOverlay` (in `zone_view.tscn`): balloon brings the frosted card → letters pop with sounds → word + unfrost + confetti → card flies into its enclosure; tap hurries
- `zoo_map/dino_egg` — `DinoEgg` HUD corner: mystery → cracks → hatched (`ZooProgress.egg_*`); after a festival unlock `menu` plays the zone phrase, then `ZooMap.play_egg_moment` (found / crack / hatch)
- `album/` — `AlbumView` (window): one `AlbumZone` section per zone of `AlbumEntry` slots; collected → card (word, then `VoiceBank.get_fact(animal_id)`), not collected → wiggle + `album_empty` phrase
- `parent_corner/` — `ParentCorner` (⚙️ → ParentalGate → overlay): stats from `ProgressController.get_parent_stats()`, hard letters as `SignPlate` chips, music/sfx toggles, reset with second-press confirm → menu pops windows to the map
- Review: `Enclosure`/`ZoneIsland` show a bobbing 💭❗ for `review_in_zone`; tapping it replays that level (`ev_level_selected`); zone says `review_hint` once per session
- States come from `ZooProgress` only; components never read PData

## Game start / return

- Festival: tent tap (full zone) → `ev_start_festival({zone_id})`; return `{unlocked_zone_id}` → map unlock animation + phrase

- Start: `ev_start_level({ "level_id": int })` (or `{ "level_data": LevelData }`)
- Return: `ev_return_to_menu({ "zone_id": String, "arrived_level_id"?: int })` — level sends its own zone; arrival only after a first win
- No level → level jumps: the next animal is started from its pulsing enclosure

## Avoid

- Loading `GameScene` from menu scripts directly
- Parental gate on the window stack
