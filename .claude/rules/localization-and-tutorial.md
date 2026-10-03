---
description: Localization (none yet) and first-run easing (tutorial levels, 👆 HandHint)
paths:
  - "src/**/*.gd"
  - "src/**/*.tscn"
  - "src/levels/**/*"
---

# Localization & tutorial

## Localization — none yet

- Game is Russian-only. No `tr()`, no TranslationServer, no `.po`/`.csv` (`*.translation` is gitignored)
- Russian text lives in: `LevelData` (`word`, `parts`, `animal_display_name`), and a few `.tscn` labels
  (`menu.tscn` title, `parental_gate.tscn`, `celebration_overlay.tscn` "Ура!")
- Chrome is icon/emoji-only by design — prefer icons over new text labels. Exception: `ParentCorner` (adults read it)
- Voice clips are Russian-only (`VoiceBank`, see game rules); a new language needs its own bank
- If adding localization: use Godot's built-in TranslationServer + `tr()` keys; keep level words in `LevelData`
  (they are gameplay content, not UI strings). Add a rule file in the same task

## First run (no tutorial scene)

- Goal: launch → first word in ≤ 2 taps (map island → enclosure), zero text; first 3 animals = guaranteed joy
- `LevelData.tutorial` (generator: first `TUTORIAL_LEVELS` = 3 levels, words ≤ `TUTORIAL_MAX_WORD` letters, asserted)
- Tutorial level: 👆 drag demo after `tutorial_inactivity_sec` (not 6 s), `tutorial_magnet_radius`, win = 3 stars, 👆 taps ▶
- Menu: 👆 taps the current zone's island (`ZooMap`) and the NEXT enclosure (`ZoneView`, after the arrival) while the next level is tutorial
- The 👆 = `HandHint` (`src/ui/hand_hint/`): `tap(target)` / `drag(from, to, ghost)` / `stop()`; one static node per screen
- Other easing: `LevelData.revealed_indices` (prefilled slots) + `show_ghost_hints`
- No onboarding scene/FSM state; more first-run steps = `LevelData` flags, never an autoload
