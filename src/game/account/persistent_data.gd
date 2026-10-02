class_name PData
extends Resource

## Live progress resource (active profile slot). Mutated by ProgressController.
## Unlocks are derived (see ZooProgress), not stored.

const CURRENT_SAVE_VERSION := 3

## v1 had 12 flat levels (ids 1..12); v2 ids are zone_number * 100 + index.
const V1_TO_V2_LEVEL_ID := {
	1: 103, 2: 101, 3: 102, 4: 202, 5: 801, 6: 203,
	7: 402, 8: 302, 9: 303, 10: 201, 11: 1102, 12: 206,
}

@export var save_version: int = CURRENT_SAVE_VERSION
## level_id (int as string key) -> stars 1..3. A key present = animal lives in the zoo.
@export var level_stars: Dictionary = {}
## zone_id -> festival stars 1..3. A key present = festival passed, next zone open.
@export var festival_stars: Dictionary = {}
@export var total_animals_saved: int = 0
## v3 — parent corner + review: letter -> times placed right / dropped on a wrong slot.
@export var letter_right: Dictionary = {}
@export var letter_wrong: Dictionary = {}
## Total play time and per-day seconds ("YYYY-MM-DD" -> seconds, last days only).
@export var play_seconds: int = 0
@export var play_days: Dictionary = {}
## level_id (string) -> local day number of the last play / how many reviews were done.
@export var level_last_day: Dictionary = {}
@export var level_reviews: Dictionary = {}


func reset_to_defaults() -> void:
	save_version = CURRENT_SAVE_VERSION
	level_stars = {}
	festival_stars = {}
	total_animals_saved = 0
	letter_right = {}
	letter_wrong = {}
	play_seconds = 0
	play_days = {}
	level_last_day = {}
	level_reviews = {}
	emit_changed()


func to_dict() -> Dictionary:
	return {
		"save_version": save_version,
		"level_stars": level_stars.duplicate(true),
		"festival_stars": festival_stars.duplicate(true),
		"total_animals_saved": total_animals_saved,
		"letter_right": letter_right.duplicate(),
		"letter_wrong": letter_wrong.duplicate(),
		"play_seconds": play_seconds,
		"play_days": play_days.duplicate(),
		"level_last_day": level_last_day.duplicate(),
		"level_reviews": level_reviews.duplicate(),
	}


func apply_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	var version := int(data.get("save_version", 1))
	level_stars = _int_values(data.get("level_stars", {}))
	festival_stars = _int_values(data.get("festival_stars", {}))
	total_animals_saved = int(data.get("total_animals_saved", 0))
	# v3 fields: absent in older saves → empty (nothing to migrate).
	letter_right = _int_values(data.get("letter_right", {}))
	letter_wrong = _int_values(data.get("letter_wrong", {}))
	play_seconds = int(data.get("play_seconds", 0))
	play_days = _int_values(data.get("play_days", {}))
	level_last_day = _int_values(data.get("level_last_day", {}))
	level_reviews = _int_values(data.get("level_reviews", {}))
	if version < 2:
		_migrate_v1()
	save_version = CURRENT_SAVE_VERSION
	emit_changed()


func get_stars(level_id: int) -> int:
	return int(level_stars.get(str(level_id), 0))


func get_festival_stars(zone_id: String) -> int:
	return int(festival_stars.get(zone_id, 0))


func _migrate_v1() -> void:
	var migrated := {}
	for key in level_stars:
		var new_id := int(V1_TO_V2_LEVEL_ID.get(int(key), 0))
		if new_id > 0:
			migrated[str(new_id)] = level_stars[key]
	level_stars = migrated
	festival_stars = {}


static func _int_values(raw: Variant) -> Dictionary:
	var out := {}
	if raw is Dictionary:
		for key in raw:
			out[str(key)] = int(raw[key])
	return out
