---
description: concepts/ is AI style reference only — never used by the game
---

# `concepts/` — AI style reference only

## Must

- Before changing menu/level UI look, read `concepts/ART_DIRECTION.md`
- Planned zoo meta (zones, enclosures, zone festival/exam): `concepts/ZOO_CONCEPT.md` + `zoo_mockups.html` — being implemented in stages: 1 data ✅, 2 map+zone screens ✅, 3 arrival ✅, 4 festival+joy, 5 content/photos, 6 extras
- Ship playable art under `assets/` or colocated in `src/`
- Keep `concepts/.gdignore` so Godot ignores the folder

## Never

- `res://concepts/...` in `.tscn`, `.tres`, `.gd`
- Put game scenes/scripts/runtime audio in `concepts/`
