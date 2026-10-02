class_name ZooMap
extends Control

## Zoo map: one long horizontal road through all zones, grouped into region bands.
## Fully procedural from LevelsCatalog: islands sit on a sine wave, the road is a smooth curve through them.

signal ev_zone_selected(zone: ZoneData)

@export var catalog: LevelsCatalog
@export var pdata: PData
@export var island_scene: PackedScene
@export var band_scene: PackedScene

@export_group("Layout")
@export var zone_spacing: float = 280.0
@export var region_gap: float = 190.0
@export var side_margin: float = 240.0
## Vertical swing of the road as a share of the map height.
@export_range(0.0, 0.4) var wave: float = 0.15
@export var wave_frequency: float = 1.3
@export_range(0.0, 1.0) var road_center: float = 0.58

@export_group("Nodes")
@export var scroll: ScrollContainer
@export var content: Control
@export var bands: Control
@export var road: Line2D
@export var road_stripe: Line2D
@export var islands: Control
@export var total_label: Label
@export var egg: DinoEgg

enum EggMoment { NONE, FOUND, CRACK, HATCH }

var _islands_by_zone: Dictionary = {}


func _ready() -> void:
	_build_default.call_deferred()


## F6 / standalone: if nobody called build() during the first frame, show the default profile.
func _build_default() -> void:
	if catalog and _islands_by_zone.is_empty():
		build(ZooProgress.new(catalog, pdata))


func build(progress: ZooProgress) -> void:
	for child in bands.get_children() + islands.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	_islands_by_zone.clear()
	var h := maxf(scroll.size.y, 600.0)
	var centers := PackedVector2Array()
	var x := side_margin
	var zone_i := 0
	for r in catalog.regions.size():
		var region := catalog.regions[r]
		var band_start := 0.0 if r == 0 else x - zone_spacing * 0.5 - region_gap * 0.5
		for zone in region.zones:
			var center := Vector2(x, h * road_center + sin(zone_i * wave_frequency) * h * wave)
			centers.append(center)
			_add_island(zone, center, progress)
			x += zone_spacing
			zone_i += 1
		x += region_gap
		var band_end := x - zone_spacing * 0.5 - region_gap * 0.5
		if r == catalog.regions.size() - 1:
			band_end = x - region_gap + side_margin - zone_spacing
		_add_band(region, band_start, band_end, h)
	content.custom_minimum_size = Vector2(x - region_gap - zone_spacing + side_margin, h)
	_build_road(centers)
	total_label.text = "🐾 %d / %d" % [progress.total_cleared(), catalog.count()]
	egg.setup(progress.egg_cracks(), progress.egg_max_cracks(), progress.is_egg_hatched())


func scroll_to_zone(zone: ZoneData, animated: bool = false) -> void:
	await get_tree().process_frame
	var island: Control = _islands_by_zone.get(zone.zone_id) if zone else null
	if island == null:
		return
	var target := int(maxf(0.0, island.position.x + island.size.x * 0.5 - scroll.size.x * 0.5))
	if animated:
		var tw := create_tween()
		tw.tween_property(scroll, "scroll_horizontal", target, 0.9).set_trans(Tween.TRANS_SINE)
		await tw.finished
	else:
		scroll.scroll_horizontal = target


## Camera glides from the previous zone to `zone`, then its island plays the unlock.
## The egg is rolled back to its state before this festival; play_egg_moment() then animates it.
func play_unlock(zone: ZoneData) -> void:
	var progress := ZooProgress.new(catalog, pdata)
	match _egg_moment(zone):
		EggMoment.FOUND:
			egg.setup(-1, progress.egg_max_cracks(), false)
		EggMoment.CRACK, EggMoment.HATCH:
			egg.setup(progress.egg_cracks() - 1, progress.egg_max_cracks(), false)
	var prev_idx := catalog.zone_index(zone.zone_id) - 1
	if prev_idx >= 0:
		await scroll_to_zone(catalog.get_zones()[prev_idx])
	await get_tree().create_timer(0.4).timeout
	await scroll_to_zone(zone, true)
	await get_tree().create_timer(0.5).timeout
	var island: ZoneIsland = _islands_by_zone.get(zone.zone_id)
	if island:
		await island.play_unlock()


## The egg reacts to the festival that opened `zone`: found / new crack / hatched.
func play_egg_moment(zone: ZoneData) -> void:
	match _egg_moment(zone):
		EggMoment.FOUND:
			await egg.play_found()
		EggMoment.CRACK:
			await egg.play_crack()
		EggMoment.HATCH:
			await egg.play_hatch()


func _egg_moment(zone: ZoneData) -> EggMoment:
	var idx := catalog.zone_index(zone.zone_id)
	var found := catalog.zone_index(catalog.egg_found_after)
	var hatch := catalog.zone_index(catalog.egg_hatch_zone)
	if idx <= 0 or found < 0 or hatch < 0:
		return EggMoment.NONE
	if idx == hatch:
		return EggMoment.HATCH
	if idx - 1 == found:
		return EggMoment.FOUND
	if idx - 1 > found and idx < hatch:
		return EggMoment.CRACK
	return EggMoment.NONE


func _add_island(zone: ZoneData, center: Vector2, progress: ZooProgress) -> void:
	var island := island_scene.instantiate() as ZoneIsland
	islands.add_child(island)
	island.position = center - island.size * 0.5
	var state := ZoneIsland.State.LOCKED
	if progress.is_festival_passed(zone):
		state = ZoneIsland.State.DONE
	elif progress.can_start_festival(zone):
		state = ZoneIsland.State.READY
	elif progress.is_zone_unlocked(zone):
		state = ZoneIsland.State.OPEN
	# Animals with real photos first, so the island shows faces rather than placeholders.
	var with_photo: Array[LevelData] = []
	var without: Array[LevelData] = []
	for level in zone.levels:
		if progress.is_level_cleared(level.level_id):
			(with_photo if level.animal_texture else without).append(level)
	with_photo.append_array(without)
	island.setup(zone, state, with_photo.size(), with_photo.slice(0, 3), progress.review_in_zone(zone) != null)
	island.ev_selected.connect(func(i: ZoneIsland): ev_zone_selected.emit(i.zone))
	_islands_by_zone[zone.zone_id] = island


func _add_band(region: RegionData, from_x: float, to_x: float, h: float) -> void:
	var band := band_scene.instantiate() as RegionBand
	bands.add_child(band)
	band.position = Vector2(from_x, 0)
	band.size = Vector2(to_x - from_x, h)
	band.setup(region)


func _build_road(centers: PackedVector2Array) -> void:
	var curve := Curve2D.new()
	for i in centers.size():
		var handle := Vector2(zone_spacing * 0.45, 0)
		curve.add_point(centers[i], -handle, handle)
	var points := curve.tessellate(4, 6)
	road.points = points
	road_stripe.points = points
