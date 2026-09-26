---
description: Level gameplay scene rules
paths:
  - "src/game/scenes/game/**/*"
---

# Game / level scene

- Orchestration: `game.gd` resolves level → live `LevelData`
- States: `GameManager` FSM (`Playing` / `Completing` / `Victory`)
- Features: `letter_tile`, `word_slot`, `animal` (photo+blur), `celebration`
- **Letters only** of the target word; scatter randomly (no distractors)
- Grab → straighten + phoneme; magnet snap; miss → fly-up repel
- Tap filled slot → phoneme; complete → speak word + unblur photo
- Exit: `root_events.ev_return_to_menu` or `ev_start_level` (next)
