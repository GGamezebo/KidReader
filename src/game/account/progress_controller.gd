class_name ProgressController
extends Node

## The only place that mutates PData. Disk writes go through RootEvents.ev_save_progress → SaveManager.

@export var pdata: PData
@export var root_events: RootEvents
@export var catalog: LevelsCatalog


func get_zoo_progress() -> ZooProgress:
	return ZooProgress.new(catalog, pdata)


## Level won → animal moves into its enclosure.
## Returns { first_clear, stars, next_level_id (-1 = zone's last level), zone_id, zone_full }.
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
	var zone: ZoneData = catalog.get_zone_of_level(level_id) if catalog else null
	var next_id := catalog.next_in_zone(level_id) if catalog else -1
	_commit()
	return {
		"first_clear": first_clear,
		"stars": pdata.get_stars(level_id),
		"next_level_id": next_id,
		"zone_id": zone.zone_id if zone else "",
		"zone_full": get_zoo_progress().is_zone_full(zone),
	}


## Festival passed → next zone unlocks. Returns { first_pass, stars, next_zone_id ("" after the last zone) }.
func record_festival(zone_id: String, stars: int) -> Dictionary:
	if pdata == null:
		return {}
	stars = clampi(stars, 1, 3)
	var prev := pdata.get_festival_stars(zone_id)
	if stars > prev:
		pdata.festival_stars[zone_id] = stars
	var next_zone: ZoneData = catalog.next_zone(zone_id) if catalog else null
	_commit()
	return {
		"first_pass": prev <= 0,
		"stars": pdata.get_festival_stars(zone_id),
		"next_zone_id": next_zone.zone_id if next_zone else "",
	}


func _commit() -> void:
	pdata.emit_changed()
	if root_events:
		root_events.ev_save_progress.emit()
