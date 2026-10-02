class_name ProgressController
extends Node

## The only place that mutates PData. Disk writes go through RootEvents.ev_save_progress → SaveManager.

@export var pdata: PData
@export var root_events: RootEvents
@export var catalog: LevelsCatalog
## Play time is added in chunks of this many seconds (while the app has focus).
@export var play_tick: float = 30.0
## Days of per-day play time kept in the save.
@export var play_days_kept: int = 30

var _play_accum: float = 0.0


func _process(delta: float) -> void:
	_play_accum += delta
	if _play_accum >= play_tick:
		add_play_time(int(_play_accum))
		_play_accum = 0.0


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			set_process(false)
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			set_process(true)


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
	pdata.level_last_day[str(level_id)] = today()
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


## Letter placed (right) or dropped on a slot of another letter (wrong). Saved with the next commit/flush.
func record_letter(letter: String, correct: bool) -> void:
	if pdata == null or letter.is_empty():
		return
	var stats := pdata.letter_right if correct else pdata.letter_wrong
	stats[letter] = int(stats.get(letter, 0)) + 1


func add_play_time(seconds: int) -> void:
	if pdata == null or seconds <= 0:
		return
	pdata.play_seconds += seconds
	var key := Time.get_date_string_from_system()
	pdata.play_days[key] = int(pdata.play_days.get(key, 0)) + seconds
	var keys := pdata.play_days.keys()
	keys.sort()
	while keys.size() > play_days_kept:
		pdata.play_days.erase(keys.pop_front())
	if root_events:
		root_events.ev_save_progress.emit()


## Letters with the most misses (≥ 2 misses), worst ratio first.
func hard_letters(count: int = 6) -> Array[String]:
	var out: Array[String] = []
	if pdata == null:
		return out
	for letter in pdata.letter_wrong:
		if int(pdata.letter_wrong[letter]) >= 2:
			out.append(str(letter))
	out.sort_custom(func(a: String, b: String) -> bool: return _miss_ratio(a) > _miss_ratio(b))
	return out.slice(0, count)


## Everything the parent corner shows.
func get_parent_stats() -> Dictionary:
	var progress := get_zoo_progress()
	var festivals := 0
	for zone in catalog.get_zones():
		if progress.is_festival_passed(zone):
			festivals += 1
	return {
		"animals": progress.total_cleared(),
		"animals_total": catalog.count(),
		"festivals": festivals,
		"zones_total": catalog.get_zones().size(),
		"today_seconds": int(pdata.play_days.get(Time.get_date_string_from_system(), 0)),
		"total_seconds": pdata.play_seconds,
		"hard_letters": hard_letters(),
	}


## Parent corner: wipe the zoo (behind the parental gate + confirm).
func reset_progress() -> void:
	if pdata:
		pdata.reset_to_defaults()
		_commit()


## Local day number (days since epoch in the device time zone).
static func today() -> int:
	var bias_min: int = int(Time.get_time_zone_from_system().get("bias", 0))
	return int(floor((Time.get_unix_time_from_system() + bias_min * 60.0) / 86400.0))


func _miss_ratio(letter: String) -> float:
	var wrong := float(pdata.letter_wrong.get(letter, 0))
	return wrong / maxf(1.0, wrong + float(pdata.letter_right.get(letter, 0)))


func _commit() -> void:
	pdata.emit_changed()
	if root_events:
		root_events.ev_save_progress.emit()
