# KidReader (Godot 4.7)

Kids reading game: drag letters of a Russian word onto slots; a realistic animal photo behind a blur clears when the word is complete. Meta (in progress, see `concepts/ZOO_CONCEPT.md`): a zoo of 21 zones; each won level brings an animal; a full zone → reading festival → next zone. Prefer the smallest change that fits existing patterns. Do not invent parallel systems.

Godot 4.x only: `@export`/`@onready`, `signal.connect(cb)`, `instantiate()`, typed GDScript, `Input` actions. Run: open in Godot 4.7+, F5 (`main.tscn`). No automated tests.

Path-scoped rules live in `.claude/rules/` (mirrors `.cursor/rules/`).

## Stable references (critical)

- Prefer `class_name` + typed use over `preload("res://path/script.gd")`
- Prefer `@export` / `@export_file` / PackedScene assigned in the editor
- Do not add new path constants for scripts/resources unless no other option

## Target platforms (critical)

Mobile, desktop, HTML5. Every control works with touch and mouse; large finger-friendly hit targets. Isolate `OS.has_feature(...)` behind helpers (`Platform` in `src/common/platform.gd`).

## Scene isolation (critical)

Every scene must F6-run alone. Bake safe defaults into `.tres` / `@export`. Parents override at runtime via events → `initialize(data)` → `ResourceUtils.update_resource`.

## Folders

| Path | Role |
|------|------|
| `main.tscn` → `src/game/main.gd` | HFSM bootstrap host |
| `src/game/scenes/` | Screens: `app_root`, `menu` (zoo map ⇄ zone, album), `game` (level), `festival` (zone reading exam) |
| `src/features/` | Isolated gameplay features |
| `src/common/` | Shared Resources (`LevelData`, `ZoneData`, `RegionData`, `LevelsCatalog`, `DecorCatalog`, `UserSettings`) |
| `src/ui/` | Shared UI: parental gate, icon button, loading screen, `PhotoSticker`, `SignPlate`, `DragScroll`, `HandHint`, `styles/` |
| `src/levels/` | Generated campaign: `level_<id>.tres`, `zones/`, `regions/` |
| `src/game/account/` | `PData`, `ZooProgress` (unlock queries), `ProgressController`, `SaveManager` |
| `core/` | Project-agnostic only (HFSM, FSM, EventListener, ResourceUtils, shakers, window stack, `shaders/frost_blur`) — must not depend on `src/` |
| `concepts/` | AI style reference only — never loaded by game |
| `assets/` | Runtime art/fonts |
| `tools/` | Python generators: `gen_zoo_content.py` (regions/zones/levels from one table), `generate_voice.py` (TTS voice clips), `gen_photo_prompts.py` + `import_photos.py` (AI animal pictures → `assets/animals/`) |

## Layer contracts

- `src/features/`: one folder = one feature (`letter_tile`, `word_slot`, `animal`, `celebration`, `music`, `sfx`, `audio_duck`). Public surface: `ev_*` signals, `initialize`/`setup`, exported PackedScenes. Features never import other features' internals
- `ice_layer` is legacy (ice-cage reveal) and not used by any scene; animal reveal = blur shader on photo. `GameEvents.ev_ice_cracked` / `ev_animal_freed` are leftovers of it
- Level SFX + AudioDuck live on `game.tscn`; looping music on AppRoot `MusicPlayer`
- `src/game/scenes/`: orchestration only; compose features; own screen FSM/UI
- UI (critical): all **static** UI (known in advance: nodes, fixed counts, state styles) lives in `.tscn`/`.tres`; scripts bind `@export` and only switch state. Only data-driven UI is built in code, via template `.tscn` + `instantiate()`. See `.claude/rules/ui-scenes.md`

## Context flow

```
Menu --ev.start_level--> Level
Level --ev.open_menu {zone_id, arrived_level_id?}--> Menu (zone + arrival)
Menu --ev.start_festival {zone_id}--> Festival --ev.open_menu {unlocked_zone_id | zone_id}--> Menu
```

App phases via HFSM (`src/game/hfsm/app_hfsm.json`). Bridge: `RootEvents` on `app_root` → `hfsm.add_event`. In-level: `GameEvents` + `GameManager` FSM.

## Placement

- New gameplay unit → `src/features/{name}/`
- New screen → `src/game/scenes/{name}/`
- Shared Resource → `src/common/`
- Campaign content → edit the table in `tools/gen_zoo_content.py` and regenerate (never hand-edit `src/levels/`)
- Progress mutations → `ProgressController`; disk only via `RootEvents.ev_save_progress` → `SaveManager`

## Stale docs

`README.md` still describes syllables and ice melting — the game now uses letters only and a blur reveal. Trust the code and these rules.

## Keep rules accurate

When a change alters structure, contracts, or placement (new folder under `src/`/`core/`, new feature, event bus or FSM state, scene-isolation contract, HFSM JSON/path map, save schema, entry wiring), update in the **same** task both `.claude/rules/` (or this file) and the matching `.cursor/rules/*.mdc`. Keep each rule under ~50 lines, paths + must/never over prose, and fix or delete wrong rules — never leave contradictions.
