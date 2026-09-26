---
description: HFSM library architecture
paths:
  - "core/lib/hfsm/**/*"
---

# HFSM (`core/lib/hfsm`)

Port shared with Quizmatik. Keep transition semantics in sync.

## Public API

- `HFSM.new(tree, entities, scene_config={})`
- Scene nodes extend `IScene` (`initialize` / `deinit` / `on_event`)
- JSON `scene: { id, loading_screen, async_loading, on_event }`

## Must

- No KidReader types in `core/lib/hfsm`
- Heavy UI in scenes; BoundEntity for light platform logic only
