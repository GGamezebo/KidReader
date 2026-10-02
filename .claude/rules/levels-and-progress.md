---
description: Zoo campaign data (regions/zones/levels) and progress persistence
paths:
  - "src/common/**/*"
  - "src/levels/**/*"
  - "src/game/account/**/*"
  - "src/game/scenes/app_root/**/*"
  - "tools/gen_zoo_content.py"
---

# Levels, zones & progress (zoo campaign)

- Data tree: `LevelsCatalog.regions` → `RegionData.zones` → `ZoneData.levels` → `LevelData`
  (`src/common/{levels_catalog,region_data,zone_data,level_data}.gd`)
- Files: `src/levels/level_<id>.tres`, `src/levels/zones/zone_<zone_id>.tres`, `src/levels/regions/region_<id>.tres`, `src/common/levels_catalog.tres`
- **All of it is generated** by `tools/gen_zoo_content.py` from one table — edit the table, rerun, then rerun `tools/generate_voice.py`. Never hand-edit generated `.tres`
- `level_id = zone_number * 100 + index` (101…2105); `zone_id` is a string ("farm"). Both are save keys
- Photo: `assets/animals/animal_<animal_id>.jpg` is linked automatically if present; until then `LevelData.emoji` (from `EMOJI` in the generator) is the placeholder everywhere
- `LevelData.fact` (album, from `FACTS` in the generator — one short true sentence per animal; generator asserts each animal has one)
- Photos are AI-generated: `tools/gen_photo_prompts.py` (add `SUBJECTS`/`SCENES` for new animals/zones) → `concepts/photo_prompts.md`; pictures go to `tools/photo_inbox/<animal_id>.png` (gitignored) → `tools/import_photos.py` crops to 1280×720 jpg and regenerates levels
- Progress: `PData` v3 (`level_stars`, `festival_stars`, `total_animals_saved`; parent stats `letter_right`/`letter_wrong`, `play_seconds`/`play_days`; review `level_last_day`/`level_reviews`; `decor_placed` id → [x px, y share]). Unlocks are **derived**, never stored
- Unlock rules: `ZooProgress` (RefCounted): zone 1 open; zone N opens after zone N-1 festival; levels inside a zone open in order; festival needs a full zone
- «Animal misses you» is derived too: `ZooProgress.is_review_due` / `review_in_zone` (one per zone, oldest) from `level_last_day` + `REVIEW_DAYS[level_reviews]`; `record_win` on a replay counts a review; day = `ZooProgress.current_day()`
- Park decorations: `src/common/decor_catalog.tres` (`DecorCatalog` of `DecorItem` id/glyph/stars, hand-edited; `decor_id` is a save key). Open when `ZooProgress.total_stars()` ≥ `stars`; `place_decor` / `remove_decor` in `ProgressController`
- Dino egg is derived too: `LevelsCatalog.egg_found_after` / `egg_hatch_zone` (generator `EGG`) → `ZooProgress.egg_cracks()` (-1 = mystery, +1 per later festival), `is_egg_hatched()`
- Mutations: `ProgressController` only (`record_win`, `record_festival`, `record_letter` (level drops onto a slot), `add_play_time` (own `_process`, focus-aware), `reset_progress`); `get_parent_stats()` feeds the parent corner
- Disk: `SaveManager` → `user://save/progress.json`; writes only on `RootEvents.ev_save_progress` (debounced; suppressed during level; flush on level end / app close)

## Must

- Keep `level_id` / `zone_id` stable: append animals at the end of a zone, never reorder after release
- Bump `PData.CURRENT_SAVE_VERSION` + migrate in `PData.apply_dict` when the schema or ids change (v1→v2 map: `V1_TO_V2_LEVEL_ID`)
- Words ≤ 12 letters (generator asserts; level cells shrink to fit)
