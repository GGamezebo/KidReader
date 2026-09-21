class_name LevelData
extends Resource

## One campaign level: realistic animal photo + letter word.

@export var level_id: int = 1
@export var animal_id: String = "bull"
@export var animal_display_name: String = "Бык"
@export var word: String = "БЫК"
## Letters in correct order (no syllables, no distractors).
@export var parts: PackedStringArray = PackedStringArray(["Б", "Ы", "К"])
@export var animal_texture: Texture2D
## Optional prefilled slot indices (rare / tutorial).
@export var revealed_indices: PackedInt32Array = PackedInt32Array()
@export var show_ghost_hints: bool = true
@export_range(1, 3) var difficulty: int = 1
