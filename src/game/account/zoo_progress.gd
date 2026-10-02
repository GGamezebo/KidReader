class_name ZooProgress
extends RefCounted

## Read-only queries over PData + LevelsCatalog: what is unlocked, filled, next.
## Rules: zone 1 is open; zone N opens after zone N-1 festival. Inside a zone levels open in order.

## «Animal misses you»: days until a collected animal asks for a replay, by reviews done.
const REVIEW_DAYS: Array[int] = [2, 4, 7, 14, 30]

var catalog: LevelsCatalog
var pdata: PData
## Local day number used for reviews (tests may override).
var today: int = current_day()


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


## Local day number (days since epoch in the device time zone).
static func current_day() -> int:
	var bias_min: int = int(Time.get_time_zone_from_system().get("bias", 0))
	return int(floor((Time.get_unix_time_from_system() + bias_min * 60.0) / 86400.0))


## Collected animal not played for REVIEW_DAYS[reviews] days.
func is_review_due(level: LevelData) -> bool:
	if level == null or pdata == null or not is_level_cleared(level.level_id):
		return false
	var key := str(level.level_id)
	if not pdata.level_last_day.has(key):
		return false
	var reviews := int(pdata.level_reviews.get(key, 0))
	var wait := REVIEW_DAYS[mini(reviews, REVIEW_DAYS.size() - 1)]
	return today - int(pdata.level_last_day[key]) >= wait


## The one animal of the zone that misses the child (longest unseen among due), or null.
func review_in_zone(zone: ZoneData) -> LevelData:
	var best: LevelData = null
	var best_day := 0
	if zone == null:
		return null
	for level in zone.levels:
		if is_review_due(level):
			var day := int(pdata.level_last_day[str(level.level_id)])
			if best == null or day < best_day:
				best = level
				best_day = day
	return best


## Stars of all levels + festivals (park decorations open by this total).
func total_stars() -> int:
	var n := 0
	if pdata:
		for v in pdata.level_stars.values():
			n += int(v)
		for v in pdata.festival_stars.values():
			n += int(v)
	return n


func is_decor_open(item: DecorItem) -> bool:
	return item != null and total_stars() >= item.stars


## decor_id -> Vector2(x px, y share of map height) for decorations on the map.
func placed_decor() -> Dictionary:
	var out := {}
	if pdata:
		for id in pdata.decor_placed:
			var v: Array = pdata.decor_placed[id]
			out[id] = Vector2(float(v[0]), float(v[1]))
	return out


func total_cleared() -> int:
	var n := 0
	if catalog:
		for level in catalog.get_levels():
			if is_level_cleared(level.level_id):
				n += 1
	return n


## Dino egg cracks: -1 = not found yet (mystery), else festivals passed after the find (capped).
func egg_cracks() -> int:
	if catalog == null:
		return -1
	var found := catalog.zone_index(catalog.egg_found_after)
	if found < 0 or not is_festival_passed(catalog.get_zones()[found]):
		return -1
	var n := 0
	var zones := catalog.get_zones()
	for i in range(found + 1, found + 1 + egg_max_cracks()):
		if is_festival_passed(zones[i]):
			n += 1
	return n


func egg_max_cracks() -> int:
	if catalog == null:
		return 0
	return maxi(0, catalog.zone_index(catalog.egg_hatch_zone) - catalog.zone_index(catalog.egg_found_after) - 1)


func is_egg_hatched() -> bool:
	return catalog != null and is_zone_unlocked(catalog.get_zone(catalog.egg_hatch_zone))
