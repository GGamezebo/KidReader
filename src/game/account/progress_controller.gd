class_name ProgressController
extends Node

@export var pdata: PData
@export var root_events: RootEvents
@export var catalog: LevelsCatalog


func record_win(level_id: int, stars: int) -> Dictionary:
	if pdata == null:
		return {}
	stars = clampi(stars, 1, 3)
	var prev := pdata.get_stars(level_id)
	var first_clear := prev <= 0
	if stars > prev:
		pdata.level_stars[str(level_id)] = stars
	if first_clear:
		pdata.total_animals_saved += 1
	var next_id := -1
	if catalog:
		next_id = catalog.next_id(level_id)
	if next_id > 0 and next_id > pdata.highest_unlocked:
		pdata.highest_unlocked = next_id
	elif next_id < 0 and level_id >= pdata.highest_unlocked:
		# Last level: keep unlocked at current.
		pass
	pdata.emit_changed()
	if root_events:
		root_events.ev_save_progress.emit()
	return {
		"first_clear": first_clear,
		"stars": pdata.get_stars(level_id),
		"next_level_id": next_id,
	}
