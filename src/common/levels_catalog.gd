class_name LevelsCatalog
extends Resource

## Ordered campaign levels. Keep level_id stable for progress keys.

@export var levels: Array[LevelData] = []


func get_by_id(level_id: int) -> LevelData:
	for level in levels:
		if level and level.level_id == level_id:
			return level
	return null


func get_index(level_id: int) -> int:
	for i in levels.size():
		if levels[i] and levels[i].level_id == level_id:
			return i
	return -1


func next_id(level_id: int) -> int:
	var idx := get_index(level_id)
	if idx < 0 or idx + 1 >= levels.size():
		return -1
	return levels[idx + 1].level_id


func count() -> int:
	return levels.size()
