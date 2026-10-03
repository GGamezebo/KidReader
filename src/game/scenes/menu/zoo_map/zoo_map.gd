class_name ZooMap
extends Control

## Zoo map: one long horizontal road through all zones, grouped into region bands.
## Fully procedural from LevelsCatalog: islands sit on a sine wave, the road is a smooth curve through them.

signal ev_zone_selected(zone: ZoneData)
## Decoration put / moved on the map: pos.x in map px, pos.y as a share of the map height.
signal ev_decor_placed(decor_id: String, pos: Vector2)
signal ev_decor_removed(decor_id: String)

@export var catalog: LevelsCatalog
@export var pdata: PData
@export var island_scene: PackedScene
@export var band_scene: PackedScene
@export var decor_catalog: DecorCatalog
@export var decor_piece_scene: PackedScene
@export var decor_slot_scene: PackedScene
@export var voice_bank: VoiceBank

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
@export var stars_label: Label
@export var decor_layer: Control
@export var drag_layer: Control
@export var tray: Control
@export var tray_grid: Container
@export var decor_button: BaseButton
@export var decor_badge: Control
@export var decor_badge_label: Label
@export var drag_scroll: DragScroll
@export var voice_player: AudioStreamPlayer
@export var hand_hint: HandHint

enum EggMoment { NONE, FOUND, CRACK, HATCH }

var _islands_by_zone: Dictionary = {}
var _map_h: float = 600.0
var _ghost: DecorPiece
var _tray_hinted: bool = false


func _ready() -> void:
	tray.visible = false
	decor_button.pressed.connect(_toggle_tray)
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
	_build_decor(progress, h)
	_point_hand(progress)


## First run: while the next animal is a tutorial level, the 👆 taps the island it lives on.
func _point_hand(progress: ZooProgress) -> void:
	var zone := progress.current_zone()
	var next := catalog.get_by_id(progress.next_level_in_zone(zone)) if zone else null
	var island: Control = _islands_by_zone.get(zone.zone_id) if zone else null
	if next and next.tutorial and island:
		hand_hint.tap(island)
	else:
		hand_hint.stop()


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


## Park decorations: pieces on the map + the box (tray) of slots; badge = how many wait in the box.
func _build_decor(progress: ZooProgress, h: float) -> void:
	_map_h = h
	stars_label.text = "⭐ %d" % progress.total_stars()
	for child in decor_layer.get_children() + tray_grid.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	if decor_catalog == null:
		return
	var placed := progress.placed_decor()
	var waiting := 0
	for item in decor_catalog.items:
		var state := DecorSlot.State.LOCKED
		if placed.has(item.decor_id):
			state = DecorSlot.State.PLACED
			var at: Vector2 = placed[item.decor_id]
			_add_piece(item, Vector2(at.x, at.y * h))
		elif progress.is_decor_open(item):
			state = DecorSlot.State.READY
			waiting += 1
		var slot := decor_slot_scene.instantiate() as DecorSlot
		tray_grid.add_child(slot)
		slot.setup_slot(item, state)
		slot.ev_drag_started.connect(_on_slot_drag_started)
		slot.ev_dragged.connect(_on_drag_moved)
		slot.ev_dropped.connect(_on_slot_dropped)
	decor_badge.visible = waiting > 0
	decor_badge_label.text = str(waiting)


func _add_piece(item: DecorItem, center: Vector2) -> DecorPiece:
	var piece := decor_piece_scene.instantiate() as DecorPiece
	decor_layer.add_child(piece)
	piece.setup(item)
	piece.position = center - piece.custom_minimum_size * 0.5
	piece.ev_drag_started.connect(_on_piece_drag_started)
	piece.ev_dragged.connect(_on_drag_moved)
	piece.ev_dropped.connect(_on_piece_dropped)
	return piece


func _toggle_tray() -> void:
	tray.visible = not tray.visible
	if tray.visible and not _tray_hinted and voice_bank and voice_player:
		_tray_hinted = true
		var stream := voice_bank.get_phrase("decor_hint")
		if stream:
			voice_player.stream = stream
			voice_player.play()


## Drag out of the box: a ghost piece follows the finger; dropped outside the box → placed.
func _on_slot_drag_started(slot: DecorPiece) -> void:
	drag_scroll.suspended = true
	_ghost = decor_piece_scene.instantiate() as DecorPiece
	drag_layer.add_child(_ghost)
	_ghost.setup(slot.item)
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.global_position = slot.global_position
	_ghost.scale = Vector2(1.2, 1.2)


func _on_drag_moved(piece: DecorPiece, global_pos: Vector2) -> void:
	var moving: Control = _ghost if _ghost else piece
	moving.global_position = global_pos - moving.size * 0.5


func _on_slot_dropped(slot: DecorPiece, global_pos: Vector2) -> void:
	drag_scroll.suspended = false
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	if _over_tray(global_pos):
		return
	var center := _to_map(global_pos)
	_add_piece(slot.item, center).bounce()
	(slot as DecorSlot).setup_slot(slot.item, DecorSlot.State.PLACED)
	ev_decor_placed.emit(slot.item.decor_id, Vector2(center.x, center.y / _map_h))


func _on_piece_drag_started(piece: DecorPiece) -> void:
	drag_scroll.suspended = true
	piece.move_to_front()


## A piece on the map: dropped into the open box → back to the box, else it stays where dropped.
func _on_piece_dropped(piece: DecorPiece, global_pos: Vector2) -> void:
	drag_scroll.suspended = false
	if _over_tray(global_pos):
		piece.queue_free()
		ev_decor_removed.emit(piece.item.decor_id)
		return
	var center := _to_map(global_pos)
	piece.position = center - piece.size * 0.5
	piece.bounce()
	ev_decor_placed.emit(piece.item.decor_id, Vector2(center.x, center.y / _map_h))


func _over_tray(global_pos: Vector2) -> bool:
	return tray.visible and tray.get_global_rect().has_point(global_pos)


## Pointer → map content coordinates, kept inside the map.
func _to_map(global_pos: Vector2) -> Vector2:
	var p := global_pos - content.global_position
	return Vector2(clampf(p.x, 40.0, content.size.x - 40.0), clampf(p.y, _map_h * 0.12, _map_h * 0.95))


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
