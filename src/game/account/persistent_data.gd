class_name PData
extends Resource

## Live progress resource (active profile slot). Mutated by ProgressController.

const CURRENT_SAVE_VERSION := 1

@export var save_version: int = CURRENT_SAVE_VERSION
## level_id (int as string key in dict) -> stars 1..3
@export var level_stars: Dictionary = {}
@export var highest_unlocked: int = 1
@export var total_animals_saved: int = 0


func reset_to_defaults() -> void:
	save_version = CURRENT_SAVE_VERSION
	level_stars = {}
	highest_unlocked = 1
	total_animals_saved = 0
	emit_changed()


func to_dict() -> Dictionary:
	return {
		"save_version": save_version,
		"level_stars": level_stars.duplicate(true),
		"highest_unlocked": highest_unlocked,
		"total_animals_saved": total_animals_saved,
	}


func apply_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	save_version = int(data.get("save_version", CURRENT_SAVE_VERSION))
	var raw_stars: Variant = data.get("level_stars", {})
	level_stars = {}
	if raw_stars is Dictionary:
		for key in raw_stars:
			level_stars[str(key)] = int(raw_stars[key])
	highest_unlocked = int(data.get("highest_unlocked", 1))
	total_animals_saved = int(data.get("total_animals_saved", 0))
	emit_changed()


func get_stars(level_id: int) -> int:
	return int(level_stars.get(str(level_id), 0))


func is_unlocked(level_id: int) -> bool:
	return level_id <= highest_unlocked
