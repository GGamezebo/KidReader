---
description: Static UI lives in scenes/resources; only data-driven UI is built in code
paths:
  - "src/**/*.gd"
  - "src/**/*.tscn"
  - "core/**/*.gd"
---

# UI: scenes first, code only for dynamic UI

**Static UI** (elements known in advance) is built in `.tscn` / `.tres`, never in code.
**Only UI that is unknown in advance and built at runtime** may be created programmatically.

## Static → scene / resource (never `X.new()` in code)

- Screens, panels, buttons, labels, icons, fixed counts (e.g. 3 victory stars)
- Visual states known in advance (normal / success / magnet / locked): make each a
  `StyleBox` `.tres` (or theme variation), `@export` it, and swap — no `StyleBoxFlat.new()`
- Colors, fonts, sizes, margins → theme `core/theme/style.tres` or node properties in the scene
- Animations with fixed structure → `AnimationPlayer` / tweens on scene nodes

## Dynamic → code is allowed

- Item count/content depends on data: level cards, letter tiles, word slots, sparks/particles
- Even then, instantiate a template `.tscn` (`@export var item_scene: PackedScene`)
  instead of assembling `Control.new()` trees; code only sets data and position
- Tiny throw-away FX nodes (one `ColorRect` spark) may be `new()`-ed if no template fits

## Simple + procedural (user preference)

- Build screens from a few generic, data-driven components; content comes from `ZoneData`/`RegionData`, not per-zone art
- Shared components (`src/ui/`): `PhotoSticker` (FILLED/FROST/EMPTY), `SignPlate`, `IconButton`, `DragScroll` (`vertical`, `suspended` while the host drags something), `HandHint` (👆 tap/drag demo, follows its targets), styles in `src/ui/styles/*.tres`
- Positions/decor may be computed in code (sine-wave map, `_draw()` fences/bushes) — keep them seeded so the look is stable

## Check before writing UI code

1. Is the element known before the game runs? → put it in the scene
2. Does code set a style/color that has a fixed set of variants? → `.tres` + `@export`
3. Is a list built from data? → template `.tscn` + `instantiate()`
