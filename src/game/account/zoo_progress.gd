class_name ZooProgress
extends RefCounted

## Read-only queries over PData + LevelsCatalog: what is unlocked, filled, next.
## Rules: zone 1 is open; zone N opens after zone N-1 festival. Inside a zone levels open in order.

var catalog: LevelsCatalog
var pdata: PData


func _init(p_catalog: LevelsCatalog, p_pdata: PData) -> void:
	catalog = p_catalog
	pdata = p_pdata


func is_level_cleared(level_id: int) -> bool:
	return pdata != null and pdata.get_stars(level_id) > 0


func is_zone_unlocked(zone: ZoneData) -> bool:
	if catalog == null or zone == null:
		return false
	var idx := catalog.zone_index(zone.zone_id)
	if idx <= 0:
		return idx == 0
	return is_festival_passed(catalog.get_zones()[idx - 1])


func is_festival_passed(zone: ZoneData) -> bool:
	return zone != null and pdata != null and pdata.get_festival_stars(zone.zone_id) > 0


func cleared_count(zone: ZoneData) -> int:
	var n := 0
	if zone:
		for level in zone.levels:
			if level and is_level_cleared(level.level_id):
				n += 1
	return n


func is_zone_full(zone: ZoneData) -> bool:
	return zone != null and not zone.levels.is_empty() and cleared_count(zone) >= zone.levels.size()


## Festival can start: zone open, all animals collected, not yet passed (replay allowed by caller).
func can_start_festival(zone: ZoneData) -> bool:
	return is_zone_unlocked(zone) and is_zone_full(zone)


func is_level_unlocked(level_id: int) -> bool:
	if catalog == null:
		return false
	var zone := catalog.get_zone_of_level(level_id)
	if not is_zone_unlocked(zone):
		return false
	var idx := zone.index_of(level_id)
	return idx == 0 or is_level_cleared(level_id) or is_level_cleared(zone.levels[idx - 1].level_id)


## First not-yet-cleared level of the zone, or -1 when the zone is full.
func next_level_in_zone(zone: ZoneData) -> int:
	if zone:
		for level in zone.levels:
			if level and not is_level_cleared(level.level_id):
				return level.level_id
	return -1


## Zone the player is working on: first open zone whose festival is not passed (else the last zone).
func current_zone() -> ZoneData:
	if catalog == null:
		return null
	var zones := catalog.get_zones()
	for zone in zones:
		if is_zone_unlocked(zone) and not is_festival_passed(zone):
			return zone
	return zones.back() if not zones.is_empty() else null


func total_cleared() -> int:
	var n := 0
	if catalog:
		for level in catalog.get_levels():
			if is_level_cleared(level.level_id):
				n += 1
	return n
